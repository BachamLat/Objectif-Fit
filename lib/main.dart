import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/accueil.dart';
import 'screens/profil.dart';
import 'screens/programme.dart';
import 'screens/repas.dart';
import 'screens/salle.dart';
import 'store.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.charger();
  runApp(CapImcApp(state: state));
}

class CapImcApp extends StatelessWidget {
  final AppState state;
  const CapImcApp({super.key, required this.state});

  ThemeData _theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: b);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: b == Brightness.dark ? const Color(0xFF0B1019) : const Color(0xFFEDF0F5),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Objectif Fit',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const Coquille(),
      ),
    );
  }
}

class Coquille extends StatefulWidget {
  const Coquille({super.key});
  @override
  State<Coquille> createState() => _CoquilleState();
}

class _CoquilleState extends State<Coquille> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.read(context).synchroniserPas());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final st = AppScope.read(context);
    if (s == AppLifecycleState.resumed) st.synchroniserPas();
    if (s == AppLifecycleState.paused) st.sauverMaintenant();
  }

  void allerA(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      AccueilPage(allerA: allerA),
      const RepasPage(),
      const SallePage(),
      const ProgrammePage(),
      const ProfilPage(),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(bottom: false, child: IndexedStack(index: _index, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: allerA,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.photo_camera_outlined), selectedIcon: Icon(Icons.photo_camera), label: 'Repas'),
            NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Salle'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Machines'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
