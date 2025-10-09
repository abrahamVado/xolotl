
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class Identity {
  final String clientId;
  final String deviceSummary;
  final String? username;
  final String? password;

  Identity({required this.clientId, required this.deviceSummary, this.username, this.password});

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'deviceSummary': deviceSummary,
        'username': username,
        'password': password,
      };

  static const _key = 'mictlan_identity';
  static const _defaultStorage = FlutterSecureStorageIdentityStorage();

  static Future<Identity> ensureIdentity({
    IdentityStorage? storage,
    DeviceSummaryProvider? deviceSummaryProvider,
    Uuid? uuid,
  }) async {
    //1.- Selecciona los colaboradores inyectables o sus implementaciones por omisión.
    final IdentityStorage driver = storage ?? _defaultStorage;
    final DeviceSummaryProvider summaryProvider = deviceSummaryProvider ?? const AndroidDeviceSummaryProvider();
    final Uuid uuidGenerator = uuid ?? const Uuid();

    //2.- Intenta recuperar una identidad existente desde el almacenamiento seguro.
    final existing = await driver.read();
    if (existing != null) {
      final data = jsonDecode(existing) as Map<String, dynamic>;
      return Identity(
        clientId: data['clientId'],
        deviceSummary: data['deviceSummary'],
        username: data['username'],
        password: data['password'],
      );
    }

    //3.- Calcula el resumen del dispositivo y genera credenciales únicas para el cliente.
    final deviceSummary = await summaryProvider.summary();
    final clientId = uuidGenerator.v4();
    final username = 'u_${clientId.substring(0, 8)}';
    final password = uuidGenerator.v4();
    final ident = Identity(clientId: clientId, deviceSummary: deviceSummary, username: username, password: password);

    //4.- Persiste la nueva identidad serializada para uso futuro y regresa el objeto.
    await driver.write(jsonEncode(ident.toJson()));
    return ident;
  }
}

abstract class IdentityStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class FlutterSecureStorageIdentityStorage implements IdentityStorage {
  const FlutterSecureStorageIdentityStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() {
    //1.- Lee el valor persistido asociado a la identidad del cliente.
    return _storage.read(key: Identity._key);
  }

  @override
  Future<void> write(String value) {
    //2.- Guarda la representación JSON de la identidad bajo la llave fija.
    return _storage.write(key: Identity._key, value: value);
  }
}

abstract class DeviceSummaryProvider {
  Future<String> summary();
}

class AndroidDeviceSummaryProvider implements DeviceSummaryProvider {
  const AndroidDeviceSummaryProvider({DeviceInfoPlugin? plugin}) : _plugin = plugin;

  final DeviceInfoPlugin? _plugin;

  //1.- _resolvePlugin retorna la instancia inyectada o crea una nueva según sea necesario.
  DeviceInfoPlugin _resolvePlugin() {
    return _plugin ?? DeviceInfoPlugin();
  }

  @override
  Future<String> summary() async {
    //2.- Obtiene la información Android actual y arma la cadena de resumen.
    final android = await _resolvePlugin().androidInfo;
    return '${android.brand} ${android.model} (${android.id})';
  }
}
