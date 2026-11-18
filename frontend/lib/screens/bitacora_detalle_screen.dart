import 'package:flutter/material.dart';
import '../services/variador_service.dart';

class BitacoraDetalleScreen extends StatefulWidget {
  final int idVariador;
  const BitacoraDetalleScreen({super.key, required this.idVariador});

  @override
  State<BitacoraDetalleScreen> createState() => _BitacoraDetalleScreenState();
}

class _BitacoraDetalleScreenState extends State<BitacoraDetalleScreen> {
  final VariadorService _variadorService = VariadorService();
  List<EventoBitacora> _eventos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _variadorService.obtenerBitacora(widget.idVariador);
    if (!mounted) return;
    setState(() {
      _eventos = lista;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bitácora - Variador ${widget.idVariador}'),
        backgroundColor: const Color(0xFF1A2332),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _eventos.isEmpty
              ? const Center(child: Text('Sin eventos registrados todavía'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _eventos.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final e = _eventos[index];
                    final enCurso = e.finAlarma == null;
                    return ListTile(
                      leading: Icon(
                        enCurso ? Icons.warning : Icons.check_circle,
                        color: enCurso ? Colors.red : Colors.green,
                      ),
                      title: Text('Inicio: ${e.inicioTexto}'),
                      subtitle: Text(
                        enCurso
                            ? 'Alarma en curso'
                            : 'Restablecido: ${e.finTexto}',
                      ),
                      trailing: Text(e.duracionTexto),
                    );
                  },
                ),
    );
  }
}