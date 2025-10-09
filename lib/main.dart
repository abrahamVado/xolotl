
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'config.dart';
import 'screens/map_report_screen.dart';
import 'screens/consult_screen.dart';
import 'services/identity.dart';
import 'theme/theme_controller.dart';
import 'widgets/theme_mode_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Identity.ensureIdentity();
  runApp(const MictlanApp());
}

class MictlanApp extends StatefulWidget {
  const MictlanApp({super.key});

  @override
  State<MictlanApp> createState() => _MictlanAppState();
}

class _MictlanAppState extends State<MictlanApp> {
  late final ThemeController _controller;

  @override
  void initState() {
    super.initState();
    //1.- initState crea el controlador de tema para compartirlo en toda la app.
    _controller = ThemeController();
  }

  @override
  void dispose() {
    //2.- dispose libera el controlador cuando el árbol se destruye.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //3.- build envuelve la app con ThemeScope y reconstruye ante cambios de modo.
    return ThemeScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ShadcnApp(
            title: 'Mictlan Client',
            themeMode: _controller.mode,
            theme: ThemeData(colorScheme: LegacyColorSchemes.zinc()),
            darkTheme: ThemeData(colorScheme: LegacyColorSchemes.darkZinc()),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final pages = const [
    MapReportScreen(),
    ConsultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    //1.- build arma la estructura principal con AppBar, navegación y contenido dinámico.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mictlan Client'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: ThemeModeButton(),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Consult'),
        ],
      ),
    );
  }
}
