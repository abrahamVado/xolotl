
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import 'config.dart';
import 'screens/consult_screen.dart';
import 'screens/map_report_screen.dart';
import 'services/identity.dart';
import 'services/notification_service.dart';
import 'theme/shad_theme_builder.dart';
import 'theme/theme_controller.dart';
import 'widgets/theme_mode_button.dart';

//1.- firebaseMessagingBackgroundHandler procesa mensajes cuando la app está cerrada.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final service = await NotificationService.background();
  await service.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final container = ProviderContainer();
  await Identity.ensureIdentity();
  await NotificationService.initialize(container: container);
  FirebaseMessagingPlatform.onBackgroundMessage = firebaseMessagingBackgroundHandler;
  //2.- UncontrolledProviderScope reutiliza el contenedor configurado durante la inicialización.
  runApp(UncontrolledProviderScope(container: container, child: const MictlanApp()));
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
