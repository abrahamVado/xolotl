import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Verificamos que la configuración de Gradle fuerce TLS 1.2 para las descargas del wrapper.
  test('gradle.properties fuerza TLS 1.2 en las descargas', () {
    //1.- Leemos el archivo gradle.properties del módulo Android.
    final properties = File('android/gradle.properties').readAsStringSync();
    //2.- Comprobamos que TLS 1.2 está habilitado tanto para conexiones HTTPS como para el cliente TLS.
    expect(
      properties.contains('-Djdk.tls.client.protocols=TLSv1.2'),
      isTrue,
    );
    //3.- Validamos que las conexiones HTTPS también limiten los protocolos a TLS 1.2.
    expect(
      properties.contains('-Dhttps.protocols=TLSv1.2'),
      isTrue,
    );
  });
}
