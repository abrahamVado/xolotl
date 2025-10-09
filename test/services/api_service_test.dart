import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xolotl/services/api.dart';
import 'package:xolotl/services/session_service.dart';

void main() {
  group('ApiService', () {
    test('submitReport attaches authorization header and body', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'folio': 'F-123'}), 201,
            headers: {'content-type': 'application/json'});
      });
      final session = SessionService(
        client: client,
        storage: InMemoryTokenStorage(
          SessionToken(
            token: 'jwt-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            phone: '+521234567890',
          ),
        ),
      );
      final api = ApiService(client: client, session: session);

      final response = await api.submitReport(
        incidentTypeId: 'pothole',
        description: 'Bache en la avenida',
        contactEmail: 'vecino@example.com',
        lat: 19.3,
        lng: -99.1,
        address: 'Frente al parque',
      );

      expect(response, isNotNull);
      expect(captured, isNotNull);
      expect(captured!.headers['authorization'], 'Bearer jwt-token');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['incidentTypeId'], 'pothole');
      expect(body['contactPhone'], '+521234567890');
    });

    test('submitReport throws when session missing', () async {
      final client = MockClient((request) async => http.Response('unauthorized', 401));
      final session = SessionService(client: client, storage: InMemoryTokenStorage());
      final api = ApiService(client: client, session: session);

      expect(
        () => api.submitReport(
          incidentTypeId: 'pothole',
          description: 'Sin token',
          contactEmail: 'test@example.com',
          lat: 0,
          lng: 0,
          address: 'sin',
        ),
        throwsA(isA<MissingSessionException>()),
      );
    });

    test('getIncidentTypes tolerates respuestas no exitosas', () async {
      //1.- Se devuelve 500 para simular un backend indisponible.
      final client = MockClient((request) async => http.Response('error', 500));
      final api = ApiService(client: client, session: SessionService(client: client));

      //2.- Se espera lista vacía para que la UI no falle al iterar resultados.
      final tipos = await api.getIncidentTypes();
      expect(tipos, isEmpty);
    });
  });
}
