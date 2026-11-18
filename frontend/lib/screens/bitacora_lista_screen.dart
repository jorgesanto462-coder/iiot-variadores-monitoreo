import 'package:flutter/material.dart';
import '../services/variador_service.dart';
import '../widgets/main_layout.dart';
import 'bitacora_detalle_screen.dart';

class BitacoraListaScreen extends StatefulWidget {
  const BitacoraListaScreen({super.key});

  @override
  State<BitacoraListaScreen> createState() => _BitacoraListaScreenState();
}

class _BitacoraListaScreenState extends State<BitacoraListaScreen> {
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

  void _abrirBitacora(Variador v) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BitacoraDetalleScreen(idVariador: v.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pantallaActual: '/bitacora',
      titulo: 'Bitácora',
      nombreUsuario: 'admin',
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _variadores.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final v = _variadores[index];
                final bool activo = v.activo;
                final bool enAlarma = v.estado == 'ALARMA';

                Color colorIcono;
                if (!activo) {
                  colorIcono = Colors.grey;
                } else if (enAlarma) {
                  colorIcono = Colors.red;
                } else {
                  colorIcono = Colors.green;
                }

                return ListTile(
                  leading: Icon(
                    Icons.history,
                    color: colorIcono,
                    size: 32,
                  ),
                  title: Text(
                    'Variador ${v.id} — ${v.descripcion}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    !activo
                        ? 'Inactivo'
                        : enAlarma
                            ? 'En alarma'
                            : 'Normal',
                    style: TextStyle(color: colorIcono),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirBitacora(v),
                );
              },
            ),
    );
  }
}