import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Garantiza que los sabores de producto se hayan portado desde la app de referencia.
  test('android/app/build.gradle defines citizen and admin flavors', () {
    //1.- Lee el archivo build.gradle del módulo de la app.
    final appGradle = File('android/app/build.gradle').readAsStringSync();
    //2.- Verifica que la dimensión de sabores "app" exista.
    expect(
      appGradle.contains("flavorDimensions 'app'"),
      isTrue,
    );
    //3.- Asegura que el flavor citizen posea los sufijos correctos.
    expect(
      appGradle.contains("citizen {\n        //1.- Etiqueta al flavor ciudadano dentro de la dimensión principal.\n        dimension 'app'\n        //2.- Ajusta sufijos para diferenciar el identificador y la versión.\n        applicationIdSuffix '.citizen'\n        versionNameSuffix '-citizen'\n    }"),
      isTrue,
    );
    //4.- Asegura que el flavor admin posea los sufijos correctos.
    expect(
      appGradle.contains("admin {\n        //3.- Define el flavor administrativo con sus propios sufijos.\n        dimension 'app'\n        applicationIdSuffix '.admin'\n        versionNameSuffix '-admin'\n    }"),
      isTrue,
    );
  });
}
