import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class Variador {
  final int id;
  final String descripcion;
  final bool activo;
  final String estado;
  final String? enAlarmaDesde;

  Variador({
    required this.id,
    required this.descripcion,
    required this.activo,
    required this.estado,
    this.enAlarmaDesde,
  });

  factory Variador.fromJson(Map<String, dynamic> json) {
    return Variador(
      id: json['id_variador'],
      descripcion: json['descripcion'],
      activo: json['activo'],
      estado: json['estado'],
      enAlarmaDesde: json['en_alarma_desde'],
    );
  }
}

class VariadorService {
  static const String baseUrl = 'http://192.168.1.115:3000';
  final AuthService _authService = AuthService();

  // ⬇️⬇️⬇️ MÉTODOS DEL PASO 5 ⬇️⬇️⬇️

  Future<List<Variador>> obtenerVariadores() async {
    final token = await _authService.obtenerToken();

    final respuesta = await http.get(
      Uri.parse('$baseUrl/api/variadores'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron obtener los variadores');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);
    return datos.map((item) => Variador.fromJson(item)).toList();
  }

  Future<void> enviarReset(int idVariador) async {
    final token = await _authService.obtenerToken();

    final respuesta = await http.post(
      Uri.parse('$baseUrl/api/variadores/$idVariador/reset'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (respuesta.statusCode != 200) {
      final datos = jsonDecode(respuesta.body);
      throw Exception(datos['error'] ?? 'No se pudo enviar el reset');
    }
  }

  // ⬇️⬇️⬇️ MÉTODO DEL PASO 12: BITÁCORA ⬇️⬇️⬇️

  Future<List<EventoBitacora>> obtenerBitacora(int idVariador) async {
    final token = await _authService.obtenerToken();

    final respuesta = await http.get(
      Uri.parse('$baseUrl/api/variadores/$idVariador/eventos'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo obtener la bitácora');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);
    return datos.map((item) => EventoBitacora.fromJson(item)).toList();
  }

  // ⬇️⬇️⬇️ MÉTODOS DEL PASO 13: ADMINISTRACIÓN ⬇️⬇️⬇️

  Future<List<dynamic>> obtenerUsuarios() async {
    final token = await _authService.obtenerToken();
    final respuesta = await http.get(
      Uri.parse('$baseUrl/api/usuarios'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron obtener los usuarios');
    }
    return jsonDecode(respuesta.body);
  }

  Future<void> crearUsuario(
      String nombreUsuario, String password, String rol) async {
    final token = await _authService.obtenerToken();
    final respuesta = await http.post(
      Uri.parse('$baseUrl/api/usuarios'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre_usuario': nombreUsuario,
        'password': password,
        'rol': rol,
      }),
    );
    if (respuesta.statusCode != 200) {
      final datos = jsonDecode(respuesta.body);
      throw Exception(datos['error'] ?? 'No se pudo crear el usuario');
    }
  }

  Future<void> actualizarEstadoUsuario(int idUsuario, bool activo) async {
    final token = await _authService.obtenerToken();
    final respuesta = await http.patch(
      Uri.parse('$baseUrl/api/usuarios/$idUsuario/estado'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'activo': activo}),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo actualizar el estado del usuario');
    }
  }

  // ⬇️⬇️⬇️ MÉTODO NUEVO: editar nombre y/o contraseña ⬇️⬇️⬇️
  Future<void> actualizarUsuario(int idUsuario,
      {String? nombreUsuario, String? password}) async {
    final token = await _authService.obtenerToken();
    final body = <String, dynamic>{};
    if (nombreUsuario != null) body['nombre_usuario'] = nombreUsuario;
    if (password != null && password.isNotEmpty) body['password'] = password;

    if (body.isEmpty) {
      throw Exception('Nada que actualizar');
    }

    final respuesta = await http.patch(
      Uri.parse('$baseUrl/api/usuarios/$idUsuario'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (respuesta.statusCode != 200) {
      final datos = jsonDecode(respuesta.body);
      throw Exception(datos['error'] ?? 'No se pudo actualizar el usuario');
    }
  }
  // ⬆️⬆️⬆️ FIN MÉTODO NUEVO ⬆️⬆️⬆️

  Future<void> actualizarVariador(int id,
      {String? descripcion, bool? activo}) async {
    final token = await _authService.obtenerToken();
    final body = <String, dynamic>{};
    if (descripcion != null) body['descripcion'] = descripcion;
    if (activo != null) body['activo'] = activo;

    final respuesta = await http.patch(
      Uri.parse('$baseUrl/api/variadores/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo actualizar el variador');
    }
  }

  // ⬆️⬆️⬆️ FIN MÉTODOS DEL PASO 13 ⬆️⬆️⬆️
}

class EventoBitacora {
  final int id;
  final String inicioAlarma;
  final String? finAlarma;
  final int? duracionSegundos;

  EventoBitacora({
    required this.id,
    required this.inicioAlarma,
    this.finAlarma,
    this.duracionSegundos,
  });

  factory EventoBitacora.fromJson(Map<String, dynamic> json) {
    return EventoBitacora(
      id: json['id_evento'],
      inicioAlarma: json['inicio_alarma'],
      finAlarma: json['fin_alarma'],
      duracionSegundos: json['duracion_segundos'],
    );
  }

  // Convierte una fecha ISO 8601 (ej. "2026-10-04T19:00:30.000Z")
  // a un formato legible: "04/10/2026 19:00:30".
  String _formatearFecha(String fechaIso) {
    final fecha = DateTime.parse(fechaIso).toLocal();
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final segundo = fecha.second.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto:$segundo';
  }

  String get inicioTexto => _formatearFecha(inicioAlarma);

  String get finTexto {
    if (finAlarma == null) return 'En curso';
    return _formatearFecha(finAlarma!);
  }

  // Convierte segundos totales a un texto legible, como "1 min 45 seg".
  String get duracionTexto {
    if (duracionSegundos == null) return 'En curso';
    final minutos = duracionSegundos! ~/ 60;
    final segundos = duracionSegundos! % 60;
    if (minutos > 0) return '$minutos min $segundos seg';
    return '$segundos seg';
  }
}