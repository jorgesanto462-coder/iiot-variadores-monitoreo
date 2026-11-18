import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bitacora_lista_screen.dart';
import 'screens/variadores_screen.dart';
import 'screens/usuarios_screen.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoreo de Variadores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/bitacora': (_) => const BitacoraListaScreen(),
        '/variadores': (_) => const VariadoresScreen(),
        '/usuarios': (_) => const UsuariosScreen(),
      },
    );
  }
}