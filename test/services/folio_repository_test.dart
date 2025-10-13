import 'package:test/test.dart';
import 'package:xolotl/services/folio_repository.dart';
import 'package:xolotl/services/session_service.dart';

void main() {
  group('FolioRepository', () {
    test('serializes and restores entries per session', () async {
      //1.- Se configura un token válido para simular la sesión ciudadana.
      final token = SessionToken(
        token: 'jwt-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        phone: '+521234567890',
      );
      final session = SessionService(storage: InMemoryTokenStorage(token));
      //2.- Se crea un repositorio en memoria para capturar la serialización.
      final storage = InMemoryFolioStorage();
      final repository = FolioRepository(storage: storage, session: session);
      final entry = FolioEntry(
        id: 'F-001',
        timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
        latitude: 19.4326,
        longitude: -99.1332,
        status: 'submitted',
        type: 'pothole',
      );

      //3.- Se guarda el folio y posteriormente se recupera desde el repositorio.
      await repository.saveForCurrentSession(entry);
      final loaded = await repository.loadForCurrentSession();

      expect(loaded, hasLength(1));
      expect(loaded.first, equals(entry));

      //4.- Se limpia la sesión para validar que el repositorio elimina la persistencia.
      await repository.clearForCurrentSession();
      final afterClear = await repository.loadForCurrentSession();
      expect(afterClear, isEmpty);
    });

    test('FolioEntry serializes coordinates and timestamp precisely', () {
      //5.- Se crea una entrada de folio con datos de latitud y longitud concretos.
      final entry = FolioEntry(
        id: 'F-XYZ',
        timestamp: DateTime.parse('2024-02-02T08:30:00Z'),
        latitude: 18.1234,
        longitude: -96.5678,
        status: 'in_progress',
        type: 'water',
      );
      final json = entry.toJson();

      //6.- Se reconstruye la entrada para comprobar que la serialización es simétrica.
      final restored = FolioEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.timestamp, entry.timestamp);
      expect(restored.latitude, entry.latitude);
      expect(restored.longitude, entry.longitude);
      expect(restored.status, entry.status);
      expect(restored.type, entry.type);
    });
  });
}
