import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/articulo_tienda.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mascota_animada.dart';

class ArmarioScreen extends StatefulWidget {
  const ArmarioScreen({super.key});

  @override
  State<ArmarioScreen> createState() => _ArmarioScreenState();
}

class _ArmarioScreenState extends State<ArmarioScreen> {
  @override
  void initState() {
    super.initState();
    // Carga el inventario/equipados guardados en disco
    GamificationService.instance.inicializar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tienda y Guardarropa',
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
                // Saldo de Hormigasoles del usuario
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.softYellow,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.yellow, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.savings_rounded,
                              color: AppColors.darkBlue, size: 30),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tus Hormigasoles',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${gamif.hormigasoles} HS',
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.darkBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.yellow),
                        ),
                        child: Text(
                          '${gamif.inventario.length} / 3 artículos',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Vista previa de la mascota con accesorios
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.softCyan, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Vista previa de tu mascota',
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const MascotaAnimada(tamano: 105, mostrarEstado: false),
                      const SizedBox(height: 8),
                      Text(
                        gamif.equipados.isEmpty
                            ? 'Sin accesorios equipados aún'
                            : 'Accesorios equipados: ${gamif.equipados.map((id) => ArticuloTienda.catalogo.firstWhere((a) => a.id == id).nombre).join(", ")}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Catálogo de la Tienda (H12)
                Text(
                  'Catálogo de Artículos',
                  style: GoogleFonts.fredoka(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 12),

                ...ArticuloTienda.catalogo.map((articulo) {
                  return _buildTarjetaArticulo(context, articulo, gamif);
                }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTarjetaArticulo(
    BuildContext context,
    ArticuloTienda articulo,
    GamificationService gamif,
  ) {
    final comprado = gamif.estaComprado(articulo.id);
    final equipado = gamif.estaEquipado(articulo.id);
    final alcanza = gamif.hormigasoles >= articulo.precio;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: equipado
              ? AppColors.teal
              : comprado
                  ? AppColors.yellow
                  : AppColors.softTeal,
          width: equipado ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: equipado
                      ? AppColors.softTeal
                      : comprado
                          ? AppColors.softYellow
                          : AppColors.softCyan,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: equipado ? AppColors.teal : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  articulo.icono,
                  size: 28,
                  color: equipado ? AppColors.teal : AppColors.darkBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            articulo.nombre,
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (equipado) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.softTeal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Equipado ✅',
                              style: GoogleFonts.fredoka(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      articulo.descripcion,
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: AppColors.yellow, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${articulo.precio} HS',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ],
              ),
              if (!comprado)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        alcanza ? AppColors.yellow : Colors.grey.shade300,
                    foregroundColor:
                        alcanza ? AppColors.darkBlue : Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    if (!alcanza) {
                      final faltan = articulo.precio - gamif.hormigasoles;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppColors.darkBlue,
                          content: Text(
                            '⚠️ Te faltan $faltan HS para comprar este artículo.',
                            style: GoogleFonts.fredoka(color: AppColors.white),
                          ),
                        ),
                      );
                      return;
                    }

                    final exito = await gamif.comprarArticulo(articulo);
                    if (exito && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppColors.teal,
                          content: Text(
                            '🎉 ¡Compraste y equipaste ${articulo.nombre}!',
                            style: GoogleFonts.fredoka(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    alcanza ? 'Comprar' : 'Faltan HS',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        equipado ? AppColors.textMuted : AppColors.teal,
                    side: BorderSide(
                      color: equipado ? Colors.grey.shade300 : AppColors.teal,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    gamif.alternarEquipado(articulo.id);
                  },
                  icon: Icon(
                    equipado ? Icons.remove_circle_outline : Icons.check_circle,
                    size: 18,
                  ),
                  label: Text(
                    equipado ? 'Desequipar' : 'Equipar',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
