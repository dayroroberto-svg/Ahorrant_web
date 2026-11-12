import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mascota_model.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';

class MascotaAnimada extends StatefulWidget {
  final double tamano;
  final bool mostrarEstado;
  final bool interactiva;
  final VoidCallback? onTap;

  const MascotaAnimada({
    super.key,
    this.tamano = 130,
    this.mostrarEstado = true,
    this.interactiva = true,
    this.onTap,
  });

  @override
  State<MascotaAnimada> createState() => _MascotaAnimadaState();
}

class _MascotaAnimadaState extends State<MascotaAnimada>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.interactiva) {
      GamificationService.instance.acariciarMascota();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.darkBlue,
          duration: const Duration(seconds: 1),
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '¡Hormiguita feliz! +2 HS ganados 🎉',
                style: GoogleFonts.fredoka(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _obtenerRutaImagen({
    required bool tieneSombrero,
    required bool tieneGafas,
    required bool tieneMochila,
  }) {
    // Lógica para seleccionar la imagen adecuada según los accesorios equipados
    final listaEquipada = <String>[];
    if (tieneSombrero) listaEquipada.add('sombrero');
    if (tieneGafas) listaEquipada.add('gafas');
    if (tieneMochila) listaEquipada.add('mochila');

    // Orden de prioridad para combinar imágenes
    if (listaEquipada.isEmpty) {
      return 'assets/prendas/Hormiga_sin_prendas.png';
    } else if (listaEquipada.length == 1) {
      final unico = listaEquipada.first;
      if (unico == 'sombrero') return 'assets/prendas/Hormiga_con_gorra.png';
      if (unico == 'gafas') return 'assets/prendas/Hormiga_con_lentes.png';
      if (unico == 'mochila') return 'assets/prendas/Hormiga_con_mochila.png';
    } else if (listaEquipada.length == 2) {
      if (listaEquipada.contains('sombrero') &&
          listaEquipada.contains('gafas')) {
        return 'assets/prendas/Hormiga_lentes_gorra.png';
      }
      if (listaEquipada.contains('sombrero') &&
          listaEquipada.contains('mochila')) {
        return 'assets/prendas/Hormiga_mochila_gorra.png';
      }
      if (listaEquipada.contains('gafas') &&
          listaEquipada.contains('mochila')) {
        return 'assets/prendas/Hormiga_mochila_lentes.png';
      }
    } else {
      // Los tres accesorios
      return 'assets/prendas/Hormiga_lentes_gorra_mochila.png';
    }

    // Fallback a la imagen base
    return 'assets/prendas/Hormiga_sin_prendas.png';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GamificationService.instance,
      builder: (context, _) {
        final gamif = GamificationService.instance;
        final estado = gamif.estado;
        final tieneSombrero = gamif.estaEquipado('sombrero');
        final tieneGafas = gamif.estaEquipado('gafas');
        final tieneMochila = gamif.estaEquipado('mochila');
        final rutaImagen = _obtenerRutaImagen(
          tieneSombrero: tieneSombrero,
          tieneGafas: tieneGafas,
          tieneMochila: tieneMochila,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _onTap,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: estado == EstadoMascota.descansando
                          ? 0.0
                          : _rotationAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Halo decorativo
                    Container(
                      width: widget.tamano,
                      height: widget.tamano,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: estado.colorFondo,
                        border: Border.all(
                          color: estado.colorAcento,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: estado.colorAcento.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          rutaImagen,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.pest_control_rounded,
                              size: widget.tamano * 0.5,
                              color: estado.colorAcento,
                            );
                          },
                        ),
                      ),
                    ),

                    // Sombrero equipado (arriba a la izquierda)
                    if (tieneSombrero)
                      Positioned(
                        top: -6,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            size: 18,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),

                    // Gafas equipadas (arriba a la derecha)
                    if (tieneGafas)
                      Positioned(
                        top: widget.tamano * 0.28,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            size: 18,
                            color: AppColors.white,
                          ),
                        ),
                      ),

                    // Mochila equipada (abajo a la izquierda)
                    if (tieneMochila)
                      Positioned(
                        bottom: 0,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.backpack_rounded,
                            size: 18,
                            color: AppColors.white,
                          ),
                        ),
                      ),

                    // Badge de emoción / estado
                    Positioned(
                      bottom: -4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: estado.colorAcento, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              estado.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              estado.titulo,
                              style: GoogleFonts.fredoka(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.mostrarEstado) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: estado.colorFondo,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: estado.colorAcento.withValues(alpha: 0.5)),
                ),
                child: Text(
                  estado.descripcion,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

