import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xolotl/services/api.dart';
import 'package:xolotl/services/folio_repository.dart';
import 'package:xolotl/services/session_service.dart';

void main() {
  group('ApiService', () {
    test('submitReport attaches authorization header, body and saves folio', () async {
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
      final folios = FolioRepository(
        storage: InMemoryFolioStorage(),
        session: session,
      );
      final api = ApiService(client: client, session: session, folios: folios);

      final response = await api.submitReport(
        incidentTypeId: 'pothole',
        description: 'Bache en la avenida',
        contactEmail: 'vecino@example.com',
        lat: 19.3,
        lng: -99.1,
        address: 'Frente al parque',
      );

      expect(response, isNotNull);
      expect(response, isA<FolioEntry>());
      expect(response!.id, 'F-123');
      expect(response.latitude, 19.3);
      expect(captured, isNotNull);
      expect(captured!.headers['authorization'], 'Bearer jwt-token');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['incidentTypeId'], 'pothole');
      expect(body['contactPhone'], '+521234567890');
      final persisted = await folios.loadForCurrentSession();
      expect(persisted, contains(response));
    });

    test('submitReport throws when session missing', () async {
      final client = MockClient((request) async => http.Response('unauthorized', 401));
      final session = SessionService(client: client, storage: InMemoryTokenStorage());
      final folios = FolioRepository(storage: InMemoryFolioStorage(), session: session);
      final api = ApiService(client: client, session: session, folios: folios);

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
      final session = SessionService(client: client);
      final folios = FolioRepository(storage: InMemoryFolioStorage(), session: session);
      final api = ApiService(client: client, session: session, folios: folios);

      //2.- Se espera lista vacía para que la UI no falle al iterar resultados.
      final tipos = await api.getIncidentTypes();
      expect(tipos, isEmpty);
    });
  });
}
