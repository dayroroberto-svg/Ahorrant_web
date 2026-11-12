import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/clase_model.dart';
import '../theme/app_theme.dart';

class ClasesScreen extends StatelessWidget {
  const ClasesScreen({super.key});

  static const List<Clase> _clases = [
    Clase(
      numero: 1,
      titulo: '¿Qué son los gastos hormiga?',
      descripcion:
          'Aprende a identificar esos pequeños consumos que se acumulan sin que los notes.',
      url: 'https://www.youtube.com/watch?v=L2lsB1pnzAY',
      icono: Icons.pest_control_rounded,
    ),
    Clase(
      numero: 2,
      titulo: '¿Cómo identificar gastos innecesarios?',
      descripcion:
          'Clasifica tus compras y distingue lo que realmente necesitas de lo que solo quieres.',
      url: 'https://www.youtube.com/watch?v=RxwimX5KZMg',
      icono: Icons.search_rounded,
    ),
    Clase(
      numero: 3,
      titulo: '¿Cómo hacer un presupuesto personal?',
      descripcion:
          'Crea un presupuesto realista con la regla 50/30/20 y que no se te escape de las manos.',
      url: 'https://www.youtube.com/watch?v=yjeTcsZpW6c',
      icono: Icons.pie_chart_rounded,
    ),
    Clase(
      numero: 4,
      titulo: '¿Cómo organizar tus ingresos y gastos?',
      descripcion:
          'Ordena tu dinero en categorias para saber exactamente a donde se va cada sol.',
      url: 'https://www.youtube.com/watch?v=h0Cp6A1hN_M',
      icono: Icons.account_balance_wallet_rounded,
    ),
    Clase(
      numero: 5,
      titulo: '¿Cómo empezar a ahorrar dinero?',
      descripcion:
          'Primeros pasos para ahorrar aunque ganes poco: automatiza, visualiza y mide.',
      url: 'https://www.youtube.com/watch?v=ficL7RQN-0Q',
      icono: Icons.savings_rounded,
    ),
    Clase(
      numero: 6,
      titulo: '¿Cómo crear una meta de ahorro?',
      descripcion:
          'Define objetivos claros, dales fecha y registra tu progreso en el modulo de Metas.',
      url: 'https://www.youtube.com/watch?v=9hqHXGsQFrk',
      icono: Icons.flag_rounded,
    ),
    Clase(
      numero: 7,
      titulo: '¿Cómo leer tu estado de cuenta?',
      descripcion:
          'Entiende cada linea de tu estado de cuenta y detecta los cargos que no reconoces.',
      url: 'https://www.youtube.com/watch?v=dBEJ2MoN6cs&t=65s',
      icono: Icons.receipt_long_rounded,
    ),
    Clase(
      numero: 8,
      titulo: '¿Cómo usar una tarjeta de crédito?',
      descripcion:
          'Uso responsable del credito, intereses y fecha limite de pago para no sobreendeudarte.',
      url: 'https://www.youtube.com/watch?v=qkDpAwgqxKg',
      icono: Icons.credit_card_rounded,
    ),
    Clase(
      numero: 9,
      titulo: '¿Cómo evitar las deudas?',
      descripcion:
          'Estrategias practicas para salir de las deudas y no volver a caer en ellas.',
      url: 'https://www.youtube.com/watch?v=93arZrZt35E',
      icono: Icons.warning_amber_rounded,
    ),
    Clase(
      numero: 10,
      titulo: '¿Cómo mejorar tus hábitos financieros?',
      descripcion:
          'Rutinas simples y sostenibles para ahorrar mas cada mes sin mucho esfuerzo.',
      url: 'https://www.youtube.com/watch?v=K2y4VnlxP4s',
      icono: Icons.trending_up_rounded,
    ),
  ];

  Future<void> _abrirVideo(BuildContext context, Clase clase) async {
    final url = Uri.parse(clase.url);
    try {
      final abierto = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.darkBlue,
            content: Text(
              'No se pudo abrir YouTube. Revisa tu conexion a internet.',
              style: GoogleFonts.fredoka(color: AppColors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.expenseRed,
            content: Text(
              'No se pudo abrir el video de la clase.',
              style: GoogleFonts.fredoka(color: AppColors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Microlecciones',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softCyan,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyan, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded,
                    color: AppColors.teal, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aprende en 3 minutos',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toca cualquier tarjeta para ver su video en YouTube.',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lecciones Disponibles',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.yellow, width: 1.5),
                ),
                child: Text(
                  '${_clases.length} clases',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._clases.map((clase) => _buildTarjetaClase(context, clase)),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTarjetaClase(BuildContext context, Clase clase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.softTeal, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _abrirVideo(context, clase),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numero de clase + icono
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.softTeal,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.35),
                            width: 1.5),
                      ),
                      child: Icon(clase.icono, size: 26, color: AppColors.teal),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Text(
                        '${clase.numero}',
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clase.titulo,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clase.descripcion,
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Boton de ver en YouTube
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_fill_rounded,
                                color: Color(0xFFE53935), size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Ver en YouTube',
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 22, color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
