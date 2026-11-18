import 'package:flutter/material.dart';
import '../services/variador_service.dart';
import '../widgets/main_layout.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final VariadorService _service = VariadorService();
  List<dynamic> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await _service.obtenerUsuarios();
      if (!mounted) return;
      setState(() {
        _usuarios = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ⬇️⬇️⬇️ DIÁLOGO DE NUEVO USUARIO ⬇️⬇️⬇️
  void _abrirFormularioNuevoUsuario() {
    final controladorUsuario = TextEditingController();
    final controladorPassword = TextEditingController();
    String rolSeleccionado = 'OPERADOR';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nuevo usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorUsuario,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: controladorPassword,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: rolSeleccionado,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'ADMINISTRADOR', child: Text('Administrador')),
                  DropdownMenuItem(value: 'OPERADOR', child: Text('Operador')),
                  DropdownMenuItem(
                      value: 'ELECTRICISTA', child: Text('Electricista')),
                ],
                onChanged: (valor) =>
                    setStateDialog(() => rolSeleccionado = valor!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _service.crearUsuario(
                    controladorUsuario.text.trim(),
                    controladorPassword.text,
                    rolSeleccionado,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _cargar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario creado')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  // ⬇️⬇️⬇️ DIÁLOGO DE EDITAR USUARIO ⬇️⬇️⬇️
  void _abrirFormularioEditarUsuario(dynamic usuario) {
    final controladorUsuario =
        TextEditingController(text: usuario['nombre_usuario']);
    final controladorPassword = TextEditingController();
    bool cambiarPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Editar ${usuario['nombre_usuario']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controladorUsuario,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: cambiarPassword,
                      onChanged: (valor) => setStateDialog(() {
                        cambiarPassword = valor ?? false;
                        if (!cambiarPassword) {
                          controladorPassword.clear();
                        }
                      }),
                    ),
                    const Expanded(
                      child: Text('Cambiar contraseña',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                if (cambiarPassword)
                  TextField(
                    controller: controladorPassword,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                    ),
                    obscureText: true,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nuevoNombre = controladorUsuario.text.trim();
                final nuevaPass =
                    cambiarPassword ? controladorPassword.text : null;

                if (nuevoNombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('El nombre no puede estar vacío')),
                  );
                  return;
                }

                if (cambiarPassword &&
                    (nuevaPass == null || nuevaPass.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('La contraseña no puede estar vacía')),
                  );
                  return;
                }

                try {
                  await _service.actualizarUsuario(
                    usuario['id_usuario'],
                    nombreUsuario: nuevoNombre,
                    password: nuevaPass,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _cargar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Usuario actualizado correctamente')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarEstadoUsuario(int id, bool nuevoEstado) async {
    try {
      await _service.actualizarEstadoUsuario(id, nuevoEstado);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pantallaActual: '/usuarios',
      titulo: 'Usuarios',
      nombreUsuario: 'admin',
      child: Stack(
        children: [
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else
            ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _usuarios.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final u = _usuarios[index];
                final activo = u['activo'] == 1 || u['activo'] == true;
                return ListTile(
                  leading: Icon(
                    activo ? Icons.person : Icons.person_off,
                    color: activo ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  title: Text(
                    u['nombre_usuario'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(u['nombre_rol']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar',
                        onPressed: () => _abrirFormularioEditarUsuario(u),
                      ),
                      Switch(
                        value: activo,
                        onChanged: (valor) =>
                            _cambiarEstadoUsuario(u['id_usuario'], valor),
                      ),
                    ],
                  ),
                );
              },
            ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: _abrirFormularioNuevoUsuario,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}