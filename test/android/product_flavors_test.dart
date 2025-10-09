import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Garantiza que los sabores de producto se hayan portado desde la app de referencia.
  test('android/app/build.gradle.kts defines citizen and admin flavors', () {
    //1.- Lee el archivo build.gradle.kts del módulo de la app.
    final appGradle = File('android/app/build.gradle.kts').readAsStringSync();
    //2.- Verifica que la lista de dimensiones contenga la cadena "app".
    expect(
      appGradle.contains('flavorDimensions.add("app")'),
      isTrue,
    );
    //3.- Asegura que el flavor citizen declare dimensión y sufijos correctos.
    expect(
      appGradle.contains(
        'create("citizen") {\n        dimension = "app"\n        applicationIdSuffix = ".citizen"\n        versionNameSuffix = "-citizen"\n    }',
      ),
      isTrue,
    );
    //4.- Asegura que el flavor admin declare dimensión y sufijos correctos.
    expect(
      appGradle.contains(
        'create("admin") {\n        dimension = "app"\n        applicationIdSuffix = ".admin"\n        versionNameSuffix = "-admin"\n    }',
      ),
      isTrue,
    );
  });
}
