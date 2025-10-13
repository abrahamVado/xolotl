
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import 'config.dart';
import 'screens/consult_screen.dart';
import 'screens/map_report_screen.dart';
import 'services/identity.dart';
import 'theme/shad_theme_builder.dart';
import 'theme/theme_controller.dart';
import 'widgets/initialization_status_view.dart';
import 'widgets/theme_mode_button.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //2.- runApp delega la inicialización pesada a BootstrapApp para mostrar una UI temprana.
  runApp(const BootstrapApp());
}

//2.- BootstrapApp muestra una pantalla interactiva mientras se completan las tareas críticas.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<ProviderContainer> _initialization;
  ProviderContainer? _container;
  Object? _lastError;
  StackTrace? _lastStackTrace;

  @override
  void initState() {
    super.initState();
    //1.- initState dispara el proceso de arranque y conserva el Future para el FutureBuilder.
    _initialization = _initialize();
  }

  Future<ProviderContainer> _initialize() async {
    final container = ProviderContainer();
    try {
      //1.- La inicialización prepara la identidad local antes de iniciar la app completa.
      await Identity.ensureIdentity();
      _lastError = null;
      _lastStackTrace = null;
      return container;
    } catch (error, stackTrace) {
      _lastError = error;
      _lastStackTrace = stackTrace;
      container.dispose();
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  void dispose() {
    //2.- dispose limpia el contenedor cuando la app se cierra.
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //3.- FutureBuilder decide entre la UI de progreso, error o la app completa.
    return FutureBuilder<ProviderContainer>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: InitializationStatusView(
              title: 'Preparando aplicación',
              message: 'Inicializando servicios, esto puede tardar unos segundos.',
              showLoader: true,
            ),
          );
        }
        if (snapshot.hasError) {
          final detailsBuffer = StringBuffer();
          if (_lastError != null) {
            detailsBuffer.writeln(_lastError);
          }
          if (_lastStackTrace != null) {
            detailsBuffer.writeln();
            detailsBuffer.writeln(_lastStackTrace);
          }
          return MaterialApp(
            home: InitializationStatusView(
              title: 'No se pudo iniciar',
              message: 'Revisa los detalles y vuelve a intentarlo.',
              details: detailsBuffer.isEmpty ? 'Error desconocido.' : detailsBuffer.toString(),
              onRetry: _retry,
            ),
          );
        }
        _container = snapshot.data;
        return UncontrolledProviderScope(container: _container!, child: const MictlanApp());
      },
    );
  }
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
          //4.- Define esquemas de color consistentes para modos claro y oscuro usando Material 3.
          final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey);
          final darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark);
          final shadTheme = ShadThemeBuilder.fromMaterial(
            lightScheme: colorScheme,
            darkScheme: darkColorScheme,
            mode: _controller.mode,
          );
          return shad.Theme(
            data: shadTheme,
            child: MaterialApp(
              title: 'Mictlan Client',
              themeMode: _controller.mode,
              theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
              darkTheme: ThemeData(colorScheme: darkColorScheme, useMaterial3: true),
              home: const HomeScreen(),
            ),
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
