import 'package:flutter/material.dart';

//1.- ThemeController administra el modo de tema y notifica cambios a los escuchas.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialMode = ThemeMode.system}) : _mode = initialMode;

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  //2.- setTheme actualiza el modo de tema y emite notificaciones cuando hay cambios reales.
  void setTheme(ThemeMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }

  //3.- toggle alterna entre los modos claro y oscuro partiendo del modo actual.
  void toggle() {
    switch (_mode) {
      case ThemeMode.light:
        setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setTheme(ThemeMode.light);
        break;
      case ThemeMode.system:
        setTheme(ThemeMode.dark);
        break;
    }
  }

  //4.- cycle recorre los tres modos disponibles para ofrecer selección manual.
  void cycle() {
    switch (_mode) {
      case ThemeMode.light:
        setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setTheme(ThemeMode.system);
        break;
      case ThemeMode.system:
        setTheme(ThemeMode.light);
        break;
    }
  }
}

//5.- ThemeScope expone ThemeController mediante un InheritedNotifier reutilizable.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  //6.- of obtiene el controlador desde el contexto y afirma su existencia durante el desarrollo.
  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in context');
    return scope!.notifier!;
  }
}
