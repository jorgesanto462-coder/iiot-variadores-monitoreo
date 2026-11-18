import 'package:flutter/material.dart';
import '../services/variador_service.dart';

class TarjetaVariador extends StatelessWidget {
  final Variador variador;
  final VoidCallback? onRestablecer;
  final VoidCallback onVerBitacora;
  final bool puedeRestablecer;
  final bool enviandoReset;

  const TarjetaVariador({
    super.key,
    required this.variador,
    required this.onVerBitacora,
    this.onRestablecer,
    this.puedeRestablecer = false,
    this.enviandoReset = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enAlarma = variador.estado == 'ALARMA';
    final bool sinComunicacion = variador.estado == 'SIN_COMUNICACION';
    final bool activo = variador.activo;

    // Colores según el estado
    Color colorFondo;
    Color colorBorde;
    Color colorTexto;
    Color colorPunto;

    if (!activo) {
      colorFondo = const Color(0xFFECEFF1);
      colorBorde = const Color(0xFF90A4AE);
      colorTexto = const Color(0xFF546E7A);
      colorPunto = const Color(0xFF90A4AE);
    } else if (sinComunicacion) {
      colorFondo = const Color(0xFFFFF3E0);   // naranja muy claro
      colorBorde = const Color(0xFFFF9800);   // naranja
      colorTexto = const Color(0xFFE65100);   // naranja oscuro
      colorPunto = const Color(0xFFFF9800);
    } else if (enAlarma) {
      colorFondo = const Color(0xFFFFEBEE);
      colorBorde = const Color(0xFFF44336);
      colorTexto = const Color(0xFFB71C1C);
      colorPunto = const Color(0xFFF44336);
    } else {
      colorFondo = const Color(0xFFF0F9F4);
      colorBorde = const Color(0xFF4CAF50);
      colorTexto = const Color(0xFF1B5E20);
      colorPunto = const Color(0xFF4CAF50);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border.all(color: colorBorde, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Título + Estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Punto de color
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorPunto,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Título y descripción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variador ${variador.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2332),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      variador.descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF546E7A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Estado textual
              Text(
                !activo
                    ? 'INACTIVO'
                    : sinComunicacion
                        ? 'SIN COM.'
                        : enAlarma
                            ? 'ALARMA'
                            : 'NORMAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fila 2: Botones
          Row(
            children: [
              if (activo && enAlarma && puedeRestablecer)
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: enviandoReset ? null : onRestablecer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: enviandoReset
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('RESET',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              if (activo && enAlarma && puedeRestablecer)
                const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onVerBitacora,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A2332),
                      side: const BorderSide(color: Color(0xFFCFD8DC)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('BITÁCORA',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}