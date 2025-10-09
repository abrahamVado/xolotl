import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Garantizamos que el wrapper de Gradle utilice una versión compatible con Flutter.
  test('gradle wrapper uses Gradle 8.12', () {
    //1.- Leemos el archivo de propiedades del wrapper.
    final properties = File('android/gradle/wrapper/gradle-wrapper.properties')
        .readAsStringSync();
    //2.- Comprobamos que el archivo apunta a la distribución Gradle 8.12 all.
    expect(
      properties.contains(
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.12-all.zip',
      ),
      isTrue,
    );
  });
}
