
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'folio_repository.dart';
import 'session_service.dart';

//1.- MissingSessionException comunica cuando falta autenticación ciudadana.
class MissingSessionException implements Exception {
  //2.- message describe la causa para mostrarla en la UI.
  final String message;
  MissingSessionException(this.message);

  @override
  String toString() => 'MissingSessionException: $message';
}

//3.- ApiService encapsula todas las llamadas HTTP al backend de Mictlan.
class ApiService {
  final http.Client _client;
  final SessionService _session;
  final FolioRepository _folios;

  //4.- Constructor con dependencias inyectables para facilitar pruebas.
  factory ApiService({http.Client? client, SessionService? session, FolioRepository? folios}) {
    final resolvedSession = session ?? SessionService();
    return ApiService._(
      client ?? http.Client(),
      resolvedSession,
      folios ?? FolioRepository(session: resolvedSession),
    );
  }

  ApiService._(this._client, this._session, this._folios);

  //5.- _u construye las URLs absolutas respetando parámetros opcionales.
  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('${AppConfig.backendBaseUrl}$path').replace(queryParameters: q);

  //6.- getIncidentTypes consulta el catálogo público del backend.
  Future<List<Map<String, dynamic>>> getIncidentTypes() async {
    final res = await _client.get(_u('/api/v1/incident-types'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['data'],
        data['incidentTypes'],
        data['items'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate.cast<Map<String, dynamic>>();
        }
      }
    }
    return [];
  }

  //7.- submitReport envía el reporte autenticado con token ciudadano.
  Future<FolioEntry?> submitReport({
    required String incidentTypeId,
    required String description,
    required String contactEmail,
    required double lat,
    required double lng,
    required String address,
    List<String>? evidenceUrls,
  }) async {
    final token = await _session.currentToken();
    if (token == null) {
      throw MissingSessionException('Citizen session required');
    }
    final payload = <String, dynamic>{
      'incidentTypeId': incidentTypeId,
      'description': description,
      'contactEmail': contactEmail,
      'contactPhone': token.phone,
      'latitude': lat,
      'longitude': lng,
      'address': address,
    };
    if (evidenceUrls != null && evidenceUrls.isNotEmpty) {
      payload['evidenceUrls'] = evidenceUrls;
    }
    final res = await _client.post(
      _u('/api/v1/reports'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.token}',
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final entry = FolioEntry.fromApiResponse(
        data,
        latitude: lat,
        longitude: lng,
        type: incidentTypeId,
      );
      await _folios.saveForCurrentSession(entry);
      return entry;
    }
    return null;
  }

  //8.- getFolio recupera estatus del folio sin requerir autenticación.
  Future<Map<String, dynamic>?> getFolio(String folio) async {
    final res = await _client.get(_u('/api/v1/folios/$folio'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }
}
