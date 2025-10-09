
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  static final _storage = const FlutterSecureStorage();

  static Future<Identity> ensureIdentity() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) {
      final data = jsonDecode(existing) as Map<String, dynamic>;
      return Identity(
        clientId: data['clientId'],
        deviceSummary: data['deviceSummary'],
        username: data['username'],
        password: data['password'],
      );
    }
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    final deviceSummary = '${android.brand} ${android.model} (${android.id})';
    final clientId = const Uuid().v4();
    // Optionally generate username/password for backend-side provisioning
    final username = 'u_${clientId.substring(0, 8)}';
    final password = const Uuid().v4();
    final ident = Identity(clientId: clientId, deviceSummary: deviceSummary, username: username, password: password);
    await _storage.write(key: _key, value: jsonEncode(ident.toJson()));
    return ident;
  }
}
