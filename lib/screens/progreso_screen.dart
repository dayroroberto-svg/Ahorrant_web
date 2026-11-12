import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/goal_model.dart';
import '../models/registro_hormigasoles.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';

enum PeriodoProgreso { hoy, sieteDias, esteMes, todo }

extension PeriodoProgresoLabel on PeriodoProgreso {
  String get etiqueta {
    switch (this) {
      case PeriodoProgreso.hoy:
        return 'Hoy';
      case PeriodoProgreso.sieteDias:
        return '7 días';
      case PeriodoProgreso.esteMes:
        return 'Este mes';
      case PeriodoProgreso.todo:
        return 'Todo';
    }
  }

  /// Fecha minima (inclusive) del periodo, o null si es "todo".
  DateTime? get fechaMinima {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    switch (this) {
      case PeriodoProgreso.hoy:
        return hoy;
      case PeriodoProgreso.sieteDias:
        return hoy.subtract(const Duration(days: 6));
      case PeriodoProgreso.esteMes:
        return DateTime(ahora.year, ahora.month, 1);
      case PeriodoProgreso.todo:
        return null;
    }
  }
}

class _ResumenDia {
  _ResumenDia(this.fecha);
  final DateTime fecha;
  double ingresos = 0;
  double gastos = 0;
  double gastosHormiga = 0;
  int hormigasolesGanados = 0;
  int hormigasolesGastados = 0;
  int metasCreadas = 0;

  double get balance => ingresos - gastos;
  int get hormigasolesNetos => hormigasolesGanados - hormigasolesGastados;
  bool get tieneDatos =>
      ingresos > 0 ||
      gastos > 0 ||
      gastosHormiga > 0 ||
      hormigasolesGanados > 0 ||
      hormigasolesGastados > 0 ||
      metasCreadas > 0;
}

class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => ProgresoScreenState();
}

class ProgresoScreenState extends State<ProgresoScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GamificationService _gamif = GamificationService.instance;

  List<Transaction> _transacciones = [];
  List<Goal> _metas = [];
  bool _cargando = true;
  PeriodoProgreso _periodo = PeriodoProgreso.esteMes;

  @override
  void initState() {
    super.initState();
    _gamif.inicializar();
    recargar();
  }

  /// Carga los datos desde la base de datos local.
  Future<void> recargar() async {
    try {
      final transacciones = await _dbHelper.getAllTransactions();
      final metas = await _dbHelper.getAllGoals();
      if (!mounted) return;
      setState(() {
        _transacciones = transacciones;
        _metas = metas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ---------- Filtrado por periodo ----------

  bool _enPeriodo(DateTime fecha) {
    final minima = _periodo.fechaMinima;
    if (minima == null) return true;
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    return !dia.isBefore(minima);
  }

  List<Transaction> get _transaccionesPeriodo =>
      _transacciones.where((t) => _enPeriodo(t.date)).toList();

  List<Goal> get _metasPeriodo =>
      _metas.where((m) => _enPeriodo(m.fechaCreacion)).toList();

  List<RegistroHormigasoles> get _historialPeriodo => _gamif.historial
      .where((r) => _enPeriodo(r.fecha))
      .toList();

  // ---------- Totales del periodo ----------

  double get _totalIngresos => _transaccionesPeriodo
      .where((t) => t.type == 'ingreso')
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  double get _totalGastos => _transaccionesPeriodo
      .where((t) => t.type == 'egreso')
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  double get _totalGastosHormiga => _transaccionesPeriodo
      .where((t) => t.type == 'egreso' && t.category == 'gastos hormiga')
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  int get _hsGanados => _historialPeriodo
      .where((r) => r.cantidad > 0)
      .fold<int>(0, (sum, r) => sum + r.cantidad);

  int get _hsGastados => _historialPeriodo
      .where((r) => r.cantidad < 0)
      .fold<int>(0, (sum, r) => sum + r.cantidad.abs());

  // ---------- Agrupacion por dia ----------

  List<_ResumenDia> get _resumenPorDia {
    final mapa = <DateTime, _ResumenDia>{};

    _ResumenDia obtener(DateTime fecha) {
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      return mapa.putIfAbsent(dia, () => _ResumenDia(dia));
    }

    for (final t in _transaccionesPeriodo) {
      final resumen = obtener(t.date);
      if (t.type == 'ingreso') {
        resumen.ingresos += t.amount;
      } else if (t.type == 'egreso') {
        resumen.gastos += t.amount;
        if (t.category == 'gastos hormiga') {
          resumen.gastosHormiga += t.amount;
        }
      }
    }

    for (final r in _historialPeriodo) {
      final resumen = obtener(r.fecha);
      if (r.cantidad > 0) {
        resumen.hormigasolesGanados += r.cantidad;
      } else {
        resumen.hormigasolesGastados += r.cantidad.abs();
      }
    }

    for (final m in _metasPeriodo) {
      obtener(m.fechaCreacion).metasCreadas += 1;
    }

    final lista = mapa.values.where((r) => r.tieneDatos).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  // ---------- Helpers de formato ----------

  String _formatoMonto(double monto) => 'S/ ${monto.toStringAsFixed(2)}';

  String _formatoDia(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final diferencia = hoy.difference(dia).inDays;
    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Ayer';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  static const List<String> _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  String _formatoDiaLargo(DateTime fecha) =>
      '${fecha.day} de ${_meses[fecha.month - 1]}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Progreso',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: _gamif,
        builder: (context, _) {
          if (_cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          final dias = _resumenPorDia;
          final maxDia = dias.isEmpty
              ? 1.0
              : dias
                  .map((d) => d.ingresos > d.gastos ? d.ingresos : d.gastos)
                  .fold<double>(0, (a, b) => a > b ? a : b);

          return RefreshIndicator(
            onRefresh: recargar,
            color: AppColors.teal,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Encabezado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.softCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          size: 44,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Balance y Hábitos',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      Text(
                        'Control de tus gastos, ingresos y metas',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filtros por periodo
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: PeriodoProgreso.values.map((p) {
                          final activo = _periodo == p;
                          return ChoiceChip(
                            label: Text(
                              p.etiqueta,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight:
                                    activo ? FontWeight.bold : FontWeight.w500,
                                color: activo
                                    ? AppColors.darkBlue
                                    : AppColors.textDark,
                              ),
                            ),
                            selected: activo,
                            selectedColor: AppColors.yellow,
                            backgroundColor: AppColors.white,
                            side: BorderSide(
                              color: activo
                                  ? AppColors.darkBlue
                                  : AppColors.softTeal,
                              width: activo ? 2 : 1.5,
                            ),
                            onSelected: (_) {
                              setState(() => _periodo = p);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Resumen de Hormigasoles
                Text(
                  'Hormigasoles',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 10),
                _buildStat(
                  'Saldo actual',
                  '${_gamif.hormigasoles} HS',
                  Icons.savings_rounded,
                  AppColors.softYellow,
                  AppColors.darkBlue,
                  detalle: 'Total historico: ${_gamif.hormigasolesObtenidos} HS ganados',
                ),
                _buildStat(
                  'Recaudados (${_periodo.etiqueta.toLowerCase()})',
                  '+$_hsGanados HS',
                  Icons.trending_up_rounded,
                  AppColors.softTeal,
                  AppColors.teal,
                  detalle: 'Gastados en articulos: $_hsGastados HS',
                ),
                const SizedBox(height: 16),

                // Resumen financiero
                Text(
                  'Resumen Financiero',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 10),
                _buildStat(
                  'Ingresos',
                  _formatoMonto(_totalIngresos),
                  Icons.arrow_downward_rounded,
                  AppColors.softTeal,
                  AppColors.teal,
                ),
                _buildStat(
                  'Gastos',
                  _formatoMonto(_totalGastos),
                  Icons.arrow_upward_rounded,
                  const Color(0xFFFFF0F0),
                  AppColors.expenseRed,
                ),
                _buildStat(
                  'Gastos hormiga',
                  _formatoMonto(_totalGastosHormiga),
                  Icons.pest_control_rounded,
                  AppColors.softYellow,
                  AppColors.darkBlue,
                  detalle: _totalGastos > 0
                      ? '${((_totalGastosHormiga / _totalGastos) * 100).toStringAsFixed(0)}% de tus gastos'
                      : 'Sin gastos registrados',
                ),
                _buildStat(
                  'Metas creadas',
                  '${_metasPeriodo.length}',
                  Icons.flag_rounded,
                  AppColors.softCyan,
                  AppColors.cyan,
                  detalle:
                      'Total de metas: ${_metas.length} · Completadas: ${_metas.where((m) => m.estaCompleta).length}',
                ),
                _buildStat(
                  'Balance del periodo',
                  _formatoMonto(_totalIngresos - _totalGastos),
                  Icons.account_balance_wallet_rounded,
                  AppColors.softTeal,
                  AppColors.darkBlue,
                ),
                const SizedBox(height: 16),

                // Desglose por dia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Desglose por día',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    Text(
                      dias.isEmpty
                          ? 'Sin datos'
                          : '${dias.length} ${dias.length == 1 ? 'día' : 'días'}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (dias.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.softTeal, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_note_rounded,
                          size: 44,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sin movimientos en este periodo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cambia el filtro o registra movimientos desde Inicio.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...dias.map(
                    (d) => _buildTarjetaDia(d, maxDia),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(
    String label,
    String valor,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    String? detalle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softTeal, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (detalle != null)
                    Text(
                      detalle,
                      style: GoogleFonts.fredoka(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            valor,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaDia(_ResumenDia d, double maxDia) {
    final escalaIngresos =
        maxDia <= 0 ? 0.0 : (d.ingresos / maxDia).clamp(0.0, 1.0);
    final escalaGastos =
        maxDia <= 0 ? 0.0 : (d.gastos / maxDia).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softCyan, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.softCyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.teal),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatoDia(d.fecha),
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      Text(
                        _formatoDiaLargo(d.fecha),
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${d.balance >= 0 ? '+' : ''}${_formatoMonto(d.balance)}',
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: d.balance >= 0 ? AppColors.teal : AppColors.expenseRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barras comparativas ingresos vs gastos
          _buildBarra('Ingresos', escalaIngresos, AppColors.teal),
          const SizedBox(height: 6),
          _buildBarra('Gastos', escalaGastos, AppColors.expenseRed),
          if (d.gastosHormiga > 0) ...[
            const SizedBox(height: 6),
            _buildBarra(
              'Gastos hormiga',
              maxDia <= 0
                  ? 0.0
                  : (d.gastosHormiga / maxDia).clamp(0.0, 1.0),
              AppColors.yellow,
            ),
          ],
          const SizedBox(height: 12),

          // Detalle del dia
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Ingresos', _formatoMonto(d.ingresos), AppColors.teal),
              _chip('Gastos', _formatoMonto(d.gastos), AppColors.expenseRed),
              if (d.gastosHormiga > 0)
                _chip('Hormiga', _formatoMonto(d.gastosHormiga),
                    AppColors.darkBlue),
              if (d.hormigasolesGanados > 0)
                _chip('HS ganados', '+${d.hormigasolesGanados} HS',
                    AppColors.cyan),
              if (d.hormigasolesGastados > 0)
                _chip('HS gastados', '-${d.hormigasolesGastados} HS',
                    AppColors.expenseRed),
              if (d.metasCreadas > 0)
                _chip('Metas', '${d.metasCreadas}', AppColors.cyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarra(String etiqueta, double valor, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            etiqueta,
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: valor,
              minHeight: 8,
              backgroundColor: AppColors.softCyan,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String etiqueta, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$etiqueta: ',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
