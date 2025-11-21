import 'dart:io';

import 'package:test/test.dart';
import 'package:xolotl/tooling/icon_audit.dart';

void main() {
  group('auditAndroidIcons', () {
    test('detects missing icons and lists all sources', () async {
      //1.- Creamos un directorio temporal que simula android/app/src/main.
      final Directory tempRoot = Directory.systemTemp.createTempSync('icon_audit_test');
      final Directory androidMain = Directory('${tempRoot.path}${Platform.pathSeparator}main')
        ..createSync(recursive: true);

      try {
        //2.- Preparamos recursos disponibles dentro de res/drawable.
        final Directory drawableDir = Directory(
          '${androidMain.path}${Platform.pathSeparator}res${Platform.pathSeparator}drawable',
        )..createSync(recursive: true);
        File('${drawableDir.path}${Platform.pathSeparator}ic_present.xml').writeAsStringSync('<vector />');

        //3.- Referenciamos tanto un icono existente como uno faltante en el manifest.
        File('${androidMain.path}${Platform.pathSeparator}AndroidManifest.xml')
          ..writeAsStringSync('''
          <manifest xmlns:android="http://schemas.android.com/apk/res/android">
            <application
              android:icon="@drawable/ic_present"
              android:roundIcon="@drawable/ic_missing" />
          </manifest>
          ''');

        //4.- Agregamos otra referencia faltante desde un layout para verificar agregación.
        final Directory layoutDir = Directory(
          '${androidMain.path}${Platform.pathSeparator}res${Platform.pathSeparator}layout',
        )..createSync(recursive: true);
        File('${layoutDir.path}${Platform.pathSeparator}sample.xml')
          ..writeAsStringSync('<ImageView android:src="@drawable/ic_missing" />');

        //5.- Ejecutamos la auditoría y validamos que reporte el icono ausente con ambas rutas.
        final IconAuditResult result = auditAndroidIcons(androidMain);
        expect(result.missingIcons, hasLength(1));
        final MissingIcon missing = result.missingIcons.first;
        expect(missing.resourceType, 'drawable');
        expect(missing.name, 'ic_missing');
        expect(missing.sources, contains('AndroidManifest.xml'));
        expect(missing.sources, contains('res/layout/sample.xml'));
      } finally {
        //6.- Limpiamos el entorno temporal para no dejar archivos residuales.
        tempRoot.deleteSync(recursive: true);
      }
    });
  });
}
