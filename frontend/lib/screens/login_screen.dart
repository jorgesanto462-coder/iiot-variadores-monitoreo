import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controladorUsuario = TextEditingController();
  final _controladorPassword = TextEditingController();
  final _authService = AuthService();

  bool _cargando = false;
  String? _mensajeError;

  Future<void> _intentarLogin() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    final resultado = await _authService.login(
      _controladorUsuario.text.trim(),
      _controladorPassword.text,
    );

    setState(() {
      _cargando = false;
    });

    if (resultado['exito'] == true) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _mensajeError = resultado['error'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.settings_input_component,
                  size: 48, color: Color(0xFF1A2332)),
              const SizedBox(height: 16),
              const Text(
                'Monitoreo de Variadores',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controladorUsuario,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controladorPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _intentarLogin(),
              ),
              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _intentarLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2332),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Iniciar sesión',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}