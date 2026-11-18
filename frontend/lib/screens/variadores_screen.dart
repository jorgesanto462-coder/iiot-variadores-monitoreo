import 'package:flutter/material.dart';
import '../services/variador_service.dart';
import '../widgets/main_layout.dart';

class VariadoresScreen extends StatefulWidget {
  const VariadoresScreen({super.key});

  @override
  State<VariadoresScreen> createState() => _VariadoresScreenState();
}

class _VariadoresScreenState extends State<VariadoresScreen> {
  final VariadorService _service = VariadorService();
  List<Variador> _variadores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await _service.obtenerVariadores();
      if (!mounted) return;
      setState(() {
        _variadores = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _editarDescripcion(Variador v) {
    final controlador = TextEditingController(text: v.descripcion);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Variador ${v.id}'),
        content: TextField(
          controller: controlador,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _service.actualizarVariador(
                  v.id,
                  descripcion: controlador.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                _cargar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Descripción actualizada')),
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
    );
  }

  Future<void> _cambiarEstadoActivo(Variador v, bool nuevoValor) async {
    try {
      await _service.actualizarVariador(v.id, activo: nuevoValor);
      if (!mounted) return;
      _cargar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoValor
              ? 'Variador ${v.id} activado'
              : 'Variador ${v.id} desactivado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pantallaActual: '/variadores',
      titulo: 'Variadores',
      nombreUsuario: 'admin',
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _variadores.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final v = _variadores[index];
                return ListTile(
                  leading: Icon(
                    v.activo ? Icons.check_circle : Icons.circle_outlined,
                    color: v.activo ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  title: Text(
                    'Variador ${v.id} — ${v.descripcion}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    v.activo ? 'Activo' : 'Disponible para activar',
                    style: TextStyle(
                        color: v.activo ? Colors.green : Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar descripción',
                        onPressed: () => _editarDescripcion(v),
                      ),
                      Switch(
                        value: v.activo,
                        onChanged: (nuevoValor) =>
                            _cambiarEstadoActivo(v, nuevoValor),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}