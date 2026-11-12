import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/db_setup_stub.dart'
    if (dart.library.js_interop) 'services/db_setup_web.dart';
import 'theme/app_theme.dart';
import 'screens/inicio_screen.dart';
import 'screens/hormiguero_screen.dart';
import 'screens/armario_screen.dart';
import 'screens/metas_screen.dart';
import 'screens/clases_screen.dart';
import 'screens/progreso_screen.dart';

void main() {
  // En web SQLite corre sobre WebAssembly y guarda los datos en IndexedDB.
  setupDatabaseFactory();
  runApp(const AhorrantApp());
}

class AhorrantApp extends StatelessWidget {
  const AhorrantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahorrant',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final GlobalKey<InicioScreenState> _inicioKey =
      GlobalKey<InicioScreenState>();
  final GlobalKey<MetasScreenState> _metasKey =
      GlobalKey<MetasScreenState>();
  final GlobalKey<ProgresoScreenState> _progresoKey =
      GlobalKey<ProgresoScreenState>();

  late final List<Widget> _widgetOptions = <Widget>[
    InicioScreen(key: _inicioKey),
    const HormigueroScreen(),
    const ArmarioScreen(),
    MetasScreen(key: _metasKey),
    const ClasesScreen(),
    ProgresoScreen(key: _progresoKey),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Recarga los modulos que dependen de los datos guardados
    switch (index) {
      case 0:
        _inicioKey.currentState?.recargar();
        break;
      case 3:
        _metasKey.currentState?.recargar();
        break;
      case 5:
        _progresoKey.currentState?.recargar();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
          border: Border.all(color: AppColors.softTeal, width: 1.5),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, size: 32),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.castle_rounded),
                activeIcon: Icon(Icons.castle_rounded, size: 32),
                label: 'Hormiguero',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.checkroom_rounded),
                activeIcon: Icon(Icons.checkroom_rounded, size: 32),
                label: 'Armario',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag_rounded),
                activeIcon: Icon(Icons.flag_rounded, size: 32),
                label: 'Metas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_rounded),
                activeIcon: Icon(Icons.auto_stories_rounded, size: 32),
                label: 'Clases',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_rounded),
                activeIcon: Icon(Icons.insights_rounded, size: 32),
                label: 'Progreso',
              ),
            ],
            currentIndex: _selectedIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            iconSize: 28,
            selectedItemColor: AppColors.teal,
            unselectedItemColor: AppColors.textMuted.withValues(alpha: 0.8),
            selectedLabelStyle: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: GoogleFonts.fredoka(
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
            ),
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
