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
}
