import 'package:flutter/material.dart';
import 'sidebar.dart';

class MainLayout extends StatelessWidget {
  final String pantallaActual;
  final String titulo;
  final String nombreUsuario;
  final Widget child;

  const MainLayout({
    super.key,
    required this.pantallaActual,
    required this.titulo,
    required this.nombreUsuario,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool esMovil = MediaQuery.of(context).size.width < 600;

    if (esMovil) {
      // Layout para móvil: Drawer + AppBar con botón de menú
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1A2332),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        drawer: Drawer(
          width: 250,
          backgroundColor: Sidebar.colorFondo,
          child: Sidebar(
            pantallaActual: pantallaActual,
            nombreUsuario: nombreUsuario,
            cerrarDrawerAlNavegar: true,
          ),
        ),
        body: child,
      );
    }

    // Layout para escritorio: sidebar fijo + contenido
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          Sidebar(
            pantallaActual: pantallaActual,
            nombreUsuario: nombreUsuario,
            cerrarDrawerAlNavegar: false,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2332),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}