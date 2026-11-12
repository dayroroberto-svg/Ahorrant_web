import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mascota_model.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mascota_animada.dart';

class HormigueroScreen extends StatefulWidget {
  const HormigueroScreen({super.key});

  @override
  State<HormigueroScreen> createState() => _HormigueroScreenState();
}

class _HormigueroScreenState extends State<HormigueroScreen> {
  bool _reclamando = false;

  @override
  void initState() {
    super.initState();
    GamificationService.instance.inicializar();
  }

  Future<void> _reclamarObjetivoDiario() async {
    if (_reclamando) return;
    setState(() => _reclamando = true);

    final gamif = GamificationService.instance;
    final reclamado = await gamif.tentarObjetivoDiario();

    if (!mounted) {
      return;
    }
    setState(() => _reclamando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: reclamado ? AppColors.darkBlue : AppColors.expenseRed,
        content: Text(
          reclamado
              ? '🎯 ¡Objetivo diario completado! +10 HS y +20 XP ganados'
              : '⏳ Ya reclamaste el objetivo diario de hoy. Vuelve mañana.',
          style: GoogleFonts.fredoka(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tu Hormiguero',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: GamificationService.instance,
        builder: (context, _) {
          final gamif = GamificationService.instance;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de estadísticas rápidas (Hormigasoles + Racha)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.softYellow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.yellow, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.savings_rounded,
                                color: AppColors.darkBlue, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${gamif.hormigasoles} HS',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkBlue,
                                    ),
                                  ),
                                  Text(
                                    'Hormigasoles',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 11,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.softTeal,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.teal, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: AppColors.teal, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${gamif.rachaDias} días',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                  Text(
                                    'Racha activa',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 11,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Mascota Virtual Interactiva en su centro
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.softCyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🐜 Tu Mascota Virtual',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toca la hormiga para interactuar con ella',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const MascotaAnimada(tamano: 135),
                      const SizedBox(height: 16),

                      // Botones de cambio de estado (Los 4 estados de H09)
                      Text(
                        'Estados de la mascota:',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: EstadoMascota.values.map((est) {
                          final esActivo = gamif.estado == est;
                          return ChoiceChip(
                            avatar: Text(est.emoji,
                                style: const TextStyle(fontSize: 14)),
                            label: Text(
                              est.titulo,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: esActivo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: esActivo
                                    ? AppColors.darkBlue
                                    : AppColors.textDark,
                              ),
                            ),
                            selected: esActivo,
                            selectedColor: AppColors.yellow,
                            backgroundColor: AppColors.white,
                            side: BorderSide(
                              color: esActivo
                                  ? AppColors.darkBlue
                                  : Colors.grey.shade300,
                              width: esActivo ? 2 : 1,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                gamif.cambiarEstado(est);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nivel y Evolución del Hormiguero (H11)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.softTeal, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.softTeal,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.castle_rounded,
                                    color: AppColors.teal, size: 24),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nivel ${gamif.nivelHormiguero}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkBlue,
                                    ),
                                  ),
                                  Text(
                                    gamif.nombreNivel,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13,
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softCyan,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${gamif.xp % 100} / 100 XP',
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: gamif.progresoNivel,
                          minHeight: 12,
                          backgroundColor: AppColors.softTeal,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.teal),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ganas +10 XP y Hormigasoles cada vez que registras tus gastos y evitas consumos hormiga.',
                        style: GoogleFonts.fredoka(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Acciones rápidas de gamificación (H10)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        gamif.puedeReclamarObjetivoDiario ? AppColors.yellow : AppColors.softTeal,
                    foregroundColor: gamif.puedeReclamarObjetivoDiario
                        ? AppColors.darkBlue
                        : AppColors.textMuted,
                    disabledBackgroundColor: AppColors.softTeal,
                    disabledForegroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: gamif.puedeReclamarObjetivoDiario && !_reclamando
                      ? _reclamarObjetivoDiario
                      : null,
                  icon: Icon(
                    gamif.objetivoDiarioReclamadoHoy
                        ? Icons.check_circle_rounded
                        : Icons.flag_rounded,
                  ),
                  label: Text(
                    gamif.objetivoDiarioReclamadoHoy
                        ? 'Objetivo diario reclamado ✅ (vuelve mañana)'
                        : 'Reclamar Objetivo Diario (+10 HS)',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
