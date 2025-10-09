import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Garantiza que el plugin de Kotlin no vuelva a fijar una versión incompatible.
  test('android build.gradle.kts relies on plugin versions from settings', () {
    //1.- Lee el archivo build.gradle.kts de nivel de proyecto.
    final buildGradle = File('android/build.gradle.kts').readAsStringSync();
    //2.- Comprueba que no exista un bloque plugins que vuelva a fijar versiones.
    expect(buildGradle.contains('plugins'), isFalse);
    //3.- Asegura que el archivo dependa de la configuración centralizada en settings.gradle.kts.
    expect(
      buildGradle.contains('subprojects {\n    project.evaluationDependsOn(":app")\n}'),
      isTrue,
    );
  });
}
