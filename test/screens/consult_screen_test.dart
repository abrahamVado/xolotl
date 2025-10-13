import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mictlan_client/providers/folio_providers.dart';
import 'package:mictlan_client/screens/consult_screen.dart';
import 'package:mictlan_client/services/folio_repository.dart';
import 'package:mictlan_client/services/session_service.dart';

void main() {
  group('ConsultScreen', () {
    //1.- _buildRepository crea un repositorio en memoria con sesión configurada.
    Future<FolioRepository> _buildRepository(List<FolioEntry> entries) async {
      final token = SessionToken(
        token: 'jwt-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        phone: '+521111111111',
      );
      final session = SessionService(storage: InMemoryTokenStorage(token));
      final repository = FolioRepository(storage: InMemoryFolioStorage(), session: session);
      for (final entry in entries) {
        await repository.saveForCurrentSession(entry);
      }
      return repository;
    }

    testWidgets('muestra folios guardados al iniciar', (tester) async {
      //2.- Se prepara una entrada con datos representativos para la lista.
      final entry = FolioEntry(
        id: 'F-200',
        timestamp: DateTime.parse('2024-03-01T10:15:00Z'),
        latitude: 18.0001,
        longitude: -94.5599,
        status: 'submitted',
        type: 'pothole',
      );
      final repository = await _buildRepository([entry]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [folioRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ConsultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('folio-card-F-200')), findsOneWidget);
      expect(find.text('F-200'), findsOneWidget);
    });

    testWidgets('al seleccionar un folio se invoca el callback de navegación', (tester) async {
      //3.- Se asegura que el callback reciba la misma instancia almacenada.
      final entry = FolioEntry(
        id: 'F-201',
        timestamp: DateTime.parse('2024-03-02T11:45:00Z'),
        latitude: 18.1234,
        longitude: -94.6000,
        status: 'in_progress',
        type: 'water',
      );
      final repository = await _buildRepository([entry]);
      FolioEntry? navigated;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [folioRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: ConsultScreen(
              onNavigateToFolio: (value) => navigated = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('folio-card-F-201')));
      await tester.pumpAndSettle();
      expect(find.text('Open on map'), findsOneWidget);

      await tester.tap(find.text('Open on map'));
      await tester.pumpAndSettle();

      expect(navigated, equals(entry));
    });
  });
}
