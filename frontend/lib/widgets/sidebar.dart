import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class Sidebar extends StatefulWidget {
  final String pantallaActual;
  final String nombreUsuario;
  final bool cerrarDrawerAlNavegar;

  const Sidebar({
    super.key,
    required this.pantallaActual,
    required this.nombreUsuario,
    this.cerrarDrawerAlNavegar = false,
  });

  // Colores reutilizables
  static const Color colorFondo = Color(0xFF1A2332);
  static const Color colorActivo = Color(0xFF2C3E50);
  static const Color colorTexto = Color(0xFFB0BEC5);
  static const Color colorTextoActivo = Colors.white;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? _rol;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final rol = await AuthService().obtenerRol();
    if (!mounted) return;
    setState(() => _rol = rol);
  }

  void _navegar(BuildContext context, String ruta) {
    if (ruta == widget.pantallaActual) {
      if (widget.cerrarDrawerAlNavegar) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (widget.cerrarDrawerAlNavegar) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).pushReplacementNamed(ruta);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService().cerrarSesion();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icono,
    required String etiqueta,
    required String ruta,
  }) {
    final bool activo = widget.pantallaActual == ruta;
    return ListTile(
      leading: Icon(
        icono,
        color: activo ? Sidebar.colorTextoActivo : Sidebar.colorTexto,
        size: 22,
      ),
      title: Text(
        etiqueta,
        style: TextStyle(
          color: activo ? Sidebar.colorTextoActivo : Sidebar.colorTexto,
          fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: activo,
      selectedTileColor: Sidebar.colorActivo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _navegar(context, ruta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Sidebar.colorFondo,
      child: Column(
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.electric_bolt,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Monitoreo IIoT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Botón cerrar (solo visible cuando el sidebar es un Drawer)
                if (widget.cerrarDrawerAlNavegar)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),

          // Navegación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildItem(
                  context,
                  icono: Icons.dashboard,
                  etiqueta: 'Dashboard',
                  ruta: '/dashboard',
                ),
                _buildItem(
                  context,
                  icono: Icons.history,
                  etiqueta: 'Bitácora',
                  ruta: '/bitacora',
                ),
                // Solo Administrador ve "Variadores"
                if (_rol == 'ADMINISTRADOR')
                  _buildItem(
                    context,
                    icono: Icons.settings_input_component,
                    etiqueta: 'Variadores',
                    ruta: '/variadores',
                  ),
                // Solo Administrador ve "Usuarios"
                if (_rol == 'ADMINISTRADOR')
                  _buildItem(
                    context,
                    icono: Icons.people,
                    etiqueta: 'Usuarios',
                    ruta: '/usuarios',
                  ),
              ],
            ),
          ),

          const Spacer(),
          const Divider(color: Colors.white24, height: 1),

          // Usuario logueado + Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.nombreUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout,
                      color: Color(0xFFB0BEC5), size: 20),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => _cerrarSesion(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}