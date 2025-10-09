import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Validamos que el manifest principal utilice los drawables vectoriales como iconos.
  test('manifest references vector launcher icons', () {
    //1.- Leemos el contenido completo del AndroidManifest.xml.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    //2.- Comprobamos que el icono cuadrado apunta al drawable sin PNG.
    expect(
      manifest.contains('android:icon="@drawable/ic_launcher"'),
      isTrue,
    );
    //3.- Comprobamos que el icono redondo también apunta al drawable vectorial.
    expect(
      manifest.contains('android:roundIcon="@drawable/ic_launcher_round"'),
      isTrue,
    );
  });
}
