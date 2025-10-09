
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'config.dart';
import 'screens/map_report_screen.dart';
import 'screens/consult_screen.dart';
import 'services/identity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Identity.ensureIdentity();
  runApp(const MictlanApp());
}

class MictlanApp extends StatelessWidget {
  const MictlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'Mictlan Client',
      themeMode: ThemeMode.system,
      theme: ThemeData(colorScheme: LegacyColorSchemes.zinc()),
      darkTheme: ThemeData(colorScheme: LegacyColorSchemes.darkZinc()),
      home: const HomeScreen(),
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
    return Scaffold(
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
