import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'session_service.dart';

//1.- FolioEntry modela la respuesta del backend con datos de ubicación.
class FolioEntry extends Equatable {
  //2.- id identifica el folio proporcionado por el backend ciudadano.
  final String id;
  //3.- timestamp indica el momento en que se creó el folio.
  final DateTime timestamp;
  //4.- latitude conserva la coordenada norte-sur del reporte.
  final double latitude;
  //5.- longitude conserva la coordenada este-oeste del reporte.
  final double longitude;
  //6.- status expone el estado más reciente recibido para el folio.
  final String status;
  //7.- type referencia el identificador del catálogo de incidentes.
  final String type;

  const FolioEntry({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.type,
  });

  //8.- fromJson reconstruye la entrada persistida en almacenamiento local.
  factory FolioEntry.fromJson(Map<String, dynamic> json) {
    return FolioEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: (json['status'] ?? 'unknown').toString(),
      type: json['type'] as String,
    );
  }

  //9.- fromApiResponse construye el modelo usando la respuesta de submitReport.
  factory FolioEntry.fromApiResponse(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
    required String type,
    DateTime Function()? clock,
  }) {
    final createdAt = json['createdAt'] ?? json['timestamp'];
    final now = (clock ?? DateTime.now)();
    return FolioEntry(
      id: json['folio']?.toString() ?? 'unknown',
      timestamp: createdAt is String ? DateTime.tryParse(createdAt) ?? now : now,
      latitude: latitude,
      longitude: longitude,
      status: (json['status'] ?? json['state'] ?? 'unknown').toString(),
      type: type,
    );
  }

  //10.- toJson serializa la entrada para guardarla como cadena JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        'type': type,
      };

  @override
  List<Object?> get props => [id, timestamp, latitude, longitude, status, type];
}

//11.- FolioStorage define el contrato para leer y escribir folios por sesión.
abstract class FolioStorage {
  Future<List<FolioEntry>> read(String sessionKey);
  Future<void> write(String sessionKey, List<FolioEntry> entries);
  Future<void> clear(String sessionKey);
}

//12.- SecureFolioStorage persiste los folios en FlutterSecureStorage.
class SecureFolioStorage implements FolioStorage {
  final FlutterSecureStorage _storage;

  SecureFolioStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'mictlan_folios_';

  @override
  Future<List<FolioEntry>> read(String sessionKey) async {
    final raw = await _storage.read(key: '$_prefix$sessionKey');
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((dynamic e) =>
            FolioEntry.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList(growable: false);
  }

  @override
  Future<void> write(String sessionKey, List<FolioEntry> entries) async {
    final payload = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _storage.write(key: '$_prefix$sessionKey', value: payload);
  }

  @override
  Future<void> clear(String sessionKey) => _storage.delete(key: '$_prefix$sessionKey');
}

//13.- InMemoryFolioStorage habilita pruebas sin dependencias nativas.
class InMemoryFolioStorage implements FolioStorage {
  final Map<String, List<FolioEntry>> _entries = {};

  @override
  Future<List<FolioEntry>> read(String sessionKey) async {
    return List<FolioEntry>.from(_entries[sessionKey] ?? const []);
  }

  @override
  Future<void> write(String sessionKey, List<FolioEntry> entries) async {
    _entries[sessionKey] = List<FolioEntry>.from(entries);
  }

  @override
  Future<void> clear(String sessionKey) async {
    _entries.remove(sessionKey);
  }
}

//14.- FolioRepository coordina lectura y escritura de folios según la sesión.
class FolioRepository {
  final FolioStorage _storage;
  final SessionService _session;

  FolioRepository({FolioStorage? storage, SessionService? session})
      : _storage = storage ?? SecureFolioStorage(),
        _session = session ?? SessionService();

  //15.- loadForCurrentSession devuelve los folios almacenados para la persona.
  Future<List<FolioEntry>> loadForCurrentSession() async {
    final token = await _session.currentToken();
    if (token == null) {
      return [];
    }
    return _storage.read(token.phone);
  }

  //16.- saveForCurrentSession guarda o reemplaza un folio usando la sesión activa.
  Future<void> saveForCurrentSession(FolioEntry entry) async {
    final token = await _session.currentToken();
    if (token == null) {
      return;
    }
    final key = token.phone;
    final entries = await _storage.read(key);
    final updated = List<FolioEntry>.from(entries);
    final existingIndex = updated.indexWhere((e) => e.id == entry.id);
    if (existingIndex >= 0) {
      updated[existingIndex] = entry;
    } else {
      updated.add(entry);
      updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    await _storage.write(key, updated);
  }

  //17.- clearForCurrentSession permite borrar todos los folios al cerrar sesión.
  Future<void> clearForCurrentSession() async {
    final token = await _session.currentToken();
    if (token == null) {
      return;
    }
    await _storage.clear(token.phone);
  }
}
