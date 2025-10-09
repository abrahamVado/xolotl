import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Garantiza que el plugin de Kotlin no vuelva a fijar una versión incompatible.
  test('android build.gradle relies on classpath Kotlin plugin version', () {
    //1.- Lee el archivo build.gradle de nivel de proyecto.
    final buildGradle = File('android/build.gradle').readAsStringSync();
    //2.- Comprueba que el plugin se declare sin versión explícita para evitar conflictos.
    expect(
      buildGradle.contains("id 'org.jetbrains.kotlin.android' apply false"),
      isTrue,
    );
    //3.- Asegura que no haya ninguna declaración de versión rígida del plugin en el archivo.
    expect(
      buildGradle.contains("id 'org.jetbrains.kotlin.android' version"),
      isFalse,
    );
  });
}
