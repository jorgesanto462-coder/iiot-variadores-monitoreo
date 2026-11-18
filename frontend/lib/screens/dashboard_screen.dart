import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/variador_service.dart';
import '../widgets/main_layout.dart';
import '../widgets/tarjeta_variador.dart';
import 'bitacora_detalle_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final VariadorService _variadorService = VariadorService();
  List<Variador> _variadores = [];
  bool _cargando = true;
  String? _error;
  String? _rol;
  final String _nombreUsuario = '';
  Timer? _temporizador;
  int? _resetEnviando;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarVariadores();
    _temporizador = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _cargarVariadores(mostrarCarga: false));
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final rol = await AuthService().obtenerRol();
    if (!mounted) return;
    setState(() {
      _rol = rol;
    });
  }

  Future<void> _cargarVariadores({bool mostrarCarga = true}) async {
    if (mostrarCarga) setState(() => _cargando = true);

    try {
      final lista = await _variadorService.obtenerVariadores();
      if (!mounted) return;
      setState(() {
        _variadores = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo conectar con el servidor';
      });
    }
  }

  bool _puedeResetear() {
    return _rol == 'ADMINISTRADOR' || _rol == 'ELECTRICISTA';
  }

  Future<void> _confirmarYEnviarReset(Variador v) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar restablecimiento'),
        content: Text('¿Enviar comando de reset al Variador ${v.id}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _resetEnviando = v.id);
    try {
      await _variadorService.enviarReset(v.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comando de reset enviado al Variador ${v.id}')),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      _cargarVariadores(mostrarCarga: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _resetEnviando = null);
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
      pantallaActual: '/dashboard',
      titulo: 'Dashboard',
      nombreUsuario: _nombreUsuario.isEmpty ? 'admin' : _nombreUsuario,
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final bool esMovil = constraints.maxWidth < 600;
                    final int columnas = esMovil ? 1 : 2;
                    final double aspecto = esMovil ? 3.0 : 2.0;

                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        childAspectRatio: aspecto,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _variadores.length,
                      itemBuilder: (context, index) {
                        final v = _variadores[index];
                        return TarjetaVariador(
                          variador: v,
                          puedeRestablecer: _puedeResetear(),
                          enviandoReset: _resetEnviando == v.id,
                          onRestablecer: () => _confirmarYEnviarReset(v),
                          onVerBitacora: () => _abrirBitacora(v),
                        );
                      },
                    );
                  },
                ),
    );
  }
}