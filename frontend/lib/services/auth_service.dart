import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Toda la comunicación con el backend relacionada a login vive
// aquí, separada de la pantalla. Así, si más adelante cambia la
// URL del backend o la forma de guardar el token, solo se toca
// este archivo, no cada pantalla que lo usa.
class AuthService {
  // Mientras desarrollas en tu misma máquina, el backend corre en
  // localhost. Cuando muevas esto a un servidor real, este es el
  // único valor que cambiarás.
  static const String baseUrl = 'http://192.168.1.115:3000';

  Future<Map<String, dynamic>> login(String usuario, String password) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_usuario': usuario,
        'password': password,
      }),
    );

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode == 200) {
      // Guardamos el token y el rol para usarlos en el resto de
      // la aplicación sin tener que volver a pedirlos.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', datos['token']);
      await prefs.setString('rol', datos['usuario']['rol']);
      await prefs.setString('nombre_usuario', datos['usuario']['nombre_usuario']);

      return {'exito': true};
    } else {
      return {'exito': false, 'error': datos['error'] ?? 'Error desconocido'};
    }
  }

  Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> obtenerRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}