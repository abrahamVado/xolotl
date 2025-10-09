import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Verificamos que los estilos principales utilizan Material Components DayNight sin barra de acción.
  test('styles use MaterialComponents DayNight parent', () {
    //1.- Cargamos el archivo de estilos para el tema claro.
    final lightStyles =
        File('android/app/src/main/res/values/styles.xml').readAsStringSync();
    //2.- Cargamos el archivo de estilos para el tema nocturno.
    final darkStyles = File('android/app/src/main/res/values-night/styles.xml')
        .readAsStringSync();
    //3.- Comprobamos que ambos archivos declaran el tema padre correcto.
    expect(
      lightStyles
          .contains('parent="Theme.MaterialComponents.DayNight.NoActionBar"'),
      isTrue,
    );
    expect(
      darkStyles
          .contains('parent="Theme.MaterialComponents.DayNight.NoActionBar"'),
      isTrue,
    );
  });
}
