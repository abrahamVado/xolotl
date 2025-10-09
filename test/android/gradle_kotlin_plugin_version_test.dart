import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Comprueba que el plugin de Kotlin use una versión compatible con AGP 8.
  test('android build.gradle uses Kotlin plugin 1.9.24', () {
    //1.- Lee el archivo build.gradle de nivel de proyecto.
    final buildGradle = File('android/build.gradle').readAsStringSync();
    //2.- Verifica que la declaración del plugin incluya la versión 1.9.24.
    expect(
      buildGradle.contains(
        "id 'org.jetbrains.kotlin.android' version '1.9.24' apply false",
      ),
      isTrue,
    );
  });
}
