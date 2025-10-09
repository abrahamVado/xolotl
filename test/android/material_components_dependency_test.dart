import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Comprobamos que el build.gradle de la app incluye la dependencia de Material Components.
  test('android app module declares Material Components dependency', () {
    //1.- Leemos el archivo Gradle del módulo app en Kotlin DSL.
    final buildGradle =
        File('android/app/build.gradle.kts').readAsStringSync();
    //2.- Verificamos que la dependencia de Material Components está declarada con la versión esperada.
    expect(
      buildGradle.contains(
        'implementation("com.google.android.material:material:1.12.0")',
      ),
      isTrue,
    );
  });
}
