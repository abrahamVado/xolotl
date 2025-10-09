import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

//1.- SessionToken guarda token JWT, expiración y teléfono autenticado.
class SessionToken {
  final String token;
  final DateTime expiresAt;
  final String phone;

  //2.- Constructor directo usado al decodificar respuestas del backend.
  const SessionToken({required this.token, required this.expiresAt, required this.phone});

  //3.- fromJson reconstruye la sesión almacenada en almacenamiento seguro.
  factory SessionToken.fromJson(Map<String, dynamic> json) {
    return SessionToken(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      phone: json['phone'] as String,
    );
  }

  //4.- toJson serializa la sesión para persistirla como cadena JSON.
  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
        'phone': phone,
      };

  //5.- isExpired considera 5 segundos de margen para evitar tokens viejos.
  bool isExpired(DateTime Function() clock) =>
      expiresAt.isBefore(clock().add(const Duration(seconds: 5)));
}

//6.- TokenStorage define contrato para guardar sesiones.
abstract class TokenStorage {
  Future<void> save(SessionToken token);
  Future<SessionToken?> read();
  Future<void> clear();
}

//7.- SecureTokenStorage usa FlutterSecureStorage para producción.
class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'mictlan_auth_token';

  @override
  Future<void> save(SessionToken token) =>
      _storage.write(key: _key, value: jsonEncode(token.toJson()));

  @override
  Future<SessionToken?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return SessionToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

//8.- InMemoryTokenStorage facilita pruebas sin dependencias nativas.
class InMemoryTokenStorage implements TokenStorage {
  SessionToken? _token;

  InMemoryTokenStorage([this._token]);

  @override
  Future<void> save(SessionToken token) async {
    _token = token;
  }

  @override
  Future<SessionToken?> read() async => _token;

  @override
  Future<void> clear() async {
    _token = null;
  }
}

//9.- SessionService gestiona OTP y persistencia de tokens ciudadanos.
class SessionService {
  final http.Client _client;
  final TokenStorage _storage;
  final DateTime Function() _clock;
  SessionToken? _cached;

  SessionService({http.Client? client, TokenStorage? storage, DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _storage = storage ?? SecureTokenStorage(),
        _clock = clock ?? DateTime.now;

  //10.- _u arma la URL absoluta reutilizada por ambos endpoints OTP.
  Uri _u(String path) => Uri.parse('${AppConfig.backendBaseUrl}$path');

  //11.- requestOtp solicita al backend el envío de un código SMS.
  Future<bool> requestOtp(String phone) async {
    final res = await _client.post(
      _u('/api/v1/auth/otp/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return res.statusCode == 202;
  }

  //12.- verifyOtp valida el código y persiste el token emitido.
  Future<SessionToken?> verifyOtp(String phone, String code) async {
    final res = await _client.post(
      _u('/api/v1/auth/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = SessionToken(
      token: data['token'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
      phone: phone,
    );
    await _storage.save(token);
    _cached = token;
    return token;
  }

  //13.- currentToken devuelve token válido o limpia almacenamiento expirado.
  Future<SessionToken?> currentToken() async {
    if (_cached != null && !_cached!.isExpired(_clock)) {
      return _cached;
    }
    final stored = await _storage.read();
    if (stored == null) {
      _cached = null;
      return null;
    }
    if (stored.isExpired(_clock)) {
      await _storage.clear();
      _cached = null;
      return null;
    }
    _cached = stored;
    return stored;
  }

  //14.- hasValidToken simplifica verificaciones rápidas en la UI.
  Future<bool> hasValidToken() async => (await currentToken()) != null;

  //15.- currentPhone expone el número usado en la sesión activa.
  Future<String?> currentPhone() async => (await currentToken())?.phone;

  //16.- signOut borra el token guardado y reinicia el estado local.
  Future<void> signOut() async {
    await _storage.clear();
    _cached = null;
  }

  //17.- debugSetTokenOnlyForTests ayuda a inyectar estado en pruebas.
  @visibleForTesting
  Future<void> debugSetTokenOnlyForTests(SessionToken token) async {
    await _storage.save(token);
    _cached = token;
  }
}
