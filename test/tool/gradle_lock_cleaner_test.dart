import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../tool/gradle_lock_cleaner.dart' as cleaner_lib;

void main() {
  //1.- Agrupamos pruebas para verificar el comportamiento de LockCleaner.
  group('LockCleaner', () {
    test('ignores missing lock files', () async {
      //2.- Creamos instancia con reloj fijo y función delete espía.
      var deleted = false;
      final cleaner = cleaner_lib.LockCleaner(
        clock: () => DateTime(2024, 1, 1, 12),
        delete: (_) async {
          deleted = true;
        },
      );

      final outcome = await cleaner.clean(File('does-not-exist.lock'), const Duration(minutes: 5));

      expect(outcome, cleaner_lib.LockCleanOutcome.skippedMissing);
      expect(deleted, isFalse);
    });

    test('skips recent lock files', () async {
      //3.- Preparamos archivo temporal reciente y validamos que no se elimine.
      final tempDir = await Directory.systemTemp.createTemp('gradle-lock-test');
      addTearDown(() => tempDir.delete(recursive: true));
      final lockFile = File('${tempDir.path}/journal-1.lock');
      await lockFile.writeAsString('lock');
      lockFile.setLastModifiedSync(DateTime(2024, 1, 1, 11, 55));

      final cleaner = cleaner_lib.LockCleaner(clock: () => DateTime(2024, 1, 1, 12));

      final outcome = await cleaner.clean(lockFile, const Duration(minutes: 10));

      expect(outcome, cleaner_lib.LockCleanOutcome.skippedFresh);
      expect(await lockFile.exists(), isTrue);
    });

    test('removes stale lock files', () async {
      //4.- Generamos archivo viejo y comprobamos que la eliminación suceda.
      final tempDir = await Directory.systemTemp.createTemp('gradle-lock-test');
      addTearDown(() => tempDir.delete(recursive: true));
      final lockFile = File('${tempDir.path}/journal-1.lock');
      await lockFile.writeAsString('lock');
      lockFile.setLastModifiedSync(DateTime(2023, 12, 31, 10));

      final cleaner = cleaner_lib.LockCleaner(clock: () => DateTime(2024, 1, 1, 12));

      final outcome = await cleaner.clean(lockFile, const Duration(hours: 1));

      expect(outcome, cleaner_lib.LockCleanOutcome.deleted);
      expect(await lockFile.exists(), isFalse);
    });
  });

  //5.- Verificamos que resolveDefaultLockPath infiera rutas comunes correctamente.
  group('resolveDefaultLockPath', () {
    test('prefers GRADLE_USER_HOME when available', () {
      //6.- Simulamos entorno Windows con ruta personalizada y validamos el resultado.
      final path = cleaner_lib.resolveDefaultLockPath(
        {
          'GRADLE_USER_HOME': r'C:\GradleData',
        },
        treatAsWindows: true,
      );

      expect(path, r'C:\GradleData\caches\journal-1\journal-1.lock');
    });

    test('falls back to USERPROFILE', () {
      //7.- Creamos entorno donde solo USERPROFILE está definido.
      final path = cleaner_lib.resolveDefaultLockPath(
        {
          'USERPROFILE': r'C:\Users\Abraham',
        },
        treatAsWindows: true,
      );

      expect(path, r'C:\Users\Abraham\.gradle\caches\journal-1\journal-1.lock');
    });

    test('uses HOME on Unix like systems', () {
      //8.- Validamos el comportamiento cuando únicamente existe HOME.
      final path = cleaner_lib.resolveDefaultLockPath(
        {
          'HOME': '/home/developer',
        },
        treatAsWindows: false,
      );

      expect(path, '/home/developer/.gradle/caches/journal-1/journal-1.lock');
    });

    test('returns null when no variables are present', () {
      //9.- Sin variables disponibles esperamos un resultado nulo para advertir al CLI.
      final path = cleaner_lib.resolveDefaultLockPath(
        const {},
        treatAsWindows: false,
      );

      expect(path, isNull);
    });
  });
}
