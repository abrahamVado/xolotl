
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'identity.dart';

class Api {
  static Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('${AppConfig.backendBaseUrl}$path').replace(queryParameters: q);

  static Future<List<Map<String, dynamic>>> getIncidentTypes() async {
    final res = await http.get(_u('/api/v1/catalog/incident-types'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> submitReport({
    required String type,
    required String message,
    required double lat,
    required double lng,
  }) async {
    final ident = await Identity.ensureIdentity();
    final body = jsonEncode({
      'type': type,
      'message': message,
      'lat': lat,
      'lng': lng,
      'client_id': ident.clientId,
    });
    final res = await http.post(
      _u('/api/v1/reports'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getFolio(String folio) async {
    final res = await http.get(_u('/api/v1/folios/$folio'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }
}
