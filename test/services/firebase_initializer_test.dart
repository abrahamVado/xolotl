import 'package:firebase_core/firebase_core.dart';
import 'package:test/test.dart';

import 'package:mictlan_client/services/firebase_initializer.dart';

void main() {
  //1.- defineOptions crea una configuración mínima reutilizable para los escenarios de prueba.
  FirebaseOptions defineOptions() {
    return const FirebaseOptions(
      apiKey: 'test-key',
      appId: '1:111111111111:android:test',
      messagingSenderId: '111111111111',
      projectId: 'test-project',
    );
  }

  group('FirebaseInitializer.ensureInitialized', () {
    test('propaga las opciones al inicializador proporcionado', () async {
      FirebaseOptions? received;
      final initializer = FirebaseInitializer(
        initializeApp: ({String? name, FirebaseOptions? options}) async {
          //2.- Capturamos el parámetro para verificar que coincide con el esperado.
          received = options;
        },
      );

      await initializer.ensureInitialized(defineOptions());

      expect(received, isNotNull);
      expect(received!.apiKey, equals('test-key'));
    });

    test('reintenta usando la instancia existente cuando la app ya estaba creada', () async {
      var appProviderCalls = 0;
      final initializer = FirebaseInitializer(
        initializeApp: ({String? name, FirebaseOptions? options}) async {
          //3.- Simulamos el error duplicate-app que aparece al reinicializar en otro aislado.
          throw FirebaseException(plugin: 'firebase_core', code: 'duplicate-app');
        },
        appProvider: () {
          appProviderCalls++;
          //4.- Lanzamos un error controlado para evitar depender de Firebase real.
          throw StateError('existing app');
        },
      );

      await expectLater(
        initializer.ensureInitialized(defineOptions()),
        throwsA(isA<StateError>().having((error) => error.message, 'message', 'existing app')),
      );

      expect(appProviderCalls, equals(1));
    });
  });
}
