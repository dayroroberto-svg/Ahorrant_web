import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal_model.dart';
import '../services/database_helper.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => MetasScreenState();
}

class MetasScreenState extends State<MetasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GamificationService _gamif = GamificationService.instance;
  late List<Goal> _metas = [];
  bool _cargando = true;
  Set<int> _reclamados = {};

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoObjetivoController = TextEditingController();
  final _categoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gamif.inicializar();
    _cargarMetas();
    _cargarReclamados();
  }

  Future<void> _cargarReclamados() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('metas_reclamadas') ?? [];
    setState(() {
      _reclamados = ids.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toSet();
    });
  }

  Future<void> _guardarReclamados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'metas_reclamadas',
      _reclamados.map((e) => e.toString()).toList(),
    );
  }

  /// Recarga las metas desde la base de datos.
  Future<void> recargar() async {
    await _cargarMetas();
  }

  Future<void> _cargarMetas() async {
    try {
      final metas = await _dbHelper.getAllGoals();
      if (!mounted) return;
      setState(() {
        _metas = metas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar metas'), backgroundColor: AppColors.yellow),
      );
    }
  }

  Future<bool?> _mostrarDialogoCrearMeta() async {
    _tituloController.clear();
    _descripcionController.clear();
    _montoObjetivoController.clear();
    _categoriaController.clear();

    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Crear Nueva Meta', style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título de la meta',
                labelStyle: GoogleFonts.fredoka(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.fredoka(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                labelStyle: GoogleFonts.fredoka(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.fredoka(fontSize: 14),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoObjetivoController,
              decoration: InputDecoration(
                labelText: 'Monto objetivo (S/)',
                labelStyle: GoogleFonts.fredoka(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Ej: 500.00',
              ),
              style: GoogleFonts.fredoka(fontSize: 14),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoriaController,
              decoration: InputDecoration(
                labelText: 'Categoría (ej: ahorro, viaje)',
                labelStyle: GoogleFonts.fredoka(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.fredoka(fontSize: 14),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.fredoka(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final t = _tituloController.text.trim();
              final mS = _montoObjetivoController.text.trim();
              final d = _descripcionController.text.trim();
              final c = _categoriaController.text.trim();
              if (t.isEmpty || mS.isEmpty) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Por favor completa los campos obligatorios'), backgroundColor: AppColors.yellow),
                );
                return;
              }
              final mO = double.tryParse(mS);
              if (mO == null || mO <= 0) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Monto inválido'), backgroundColor: AppColors.yellow),
                );
                return;
              }
              final meta = Goal(titulo: t, descripcion: d, montoObjetivo: mO, montoActual: 0.0, categoria: c.isNotEmpty ? c : 'general');
              try {
                await _dbHelper.insertGoal(meta);
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop(true);
                }
              } catch (_) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('Error al crear la meta'), backgroundColor: AppColors.yellow),
                  );
                  Navigator.of(dialogCtx).pop(false);
                }
              }
            },
            child: Text('Crear', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoAgregarIngreso(Goal meta) async {
    final controlMonto = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Agregar Ingreso a "${meta.titulo}"',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(children: [
              TextField(
                controller: controlMonto,
                decoration: InputDecoration(
                  labelText: 'Monto del ingreso (S/)',
                  labelStyle: GoogleFonts.fredoka(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Ej: 100.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.fredoka(fontSize: 14),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.fredoka(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final montoStr = controlMonto.text.trim();
                if (montoStr.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingrese un monto'),
                      backgroundColor: AppColors.yellow,
                    ),
                  );
                  return;
                }

                final monto = double.tryParse(montoStr);
                if (monto == null || monto <= 0) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Monto inválido'),
                      backgroundColor: AppColors.yellow,
                    ),
                  );
                  return;
                }

                final metaActualizada = meta.copyWith(
                  montoActual: meta.montoActual + monto,
                );

                await _dbHelper.updateGoal(metaActualizada);

                // CLOSE the dialog FIRST
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }

                // Then reload and show feedback
                await _cargarMetas();

                if (!mounted) return;

                if (metaActualizada.estaCompleta) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🎉 ¡Meta completada! Reclama tus hormigasoles.',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.softTeal,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ingreso de S/ ${monto.toStringAsFixed(2)} agregado. Progreso: ${metaActualizada.progresoString}',
                        style: GoogleFonts.fredoka(color: AppColors.textDark),
                      ),
                      backgroundColor: AppColors.softTeal,
                    ),
                  );
                }
              },
              child: Text(
                'Agregar',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Calcular hormigasoles premio: 1 HS por cada 10 S/, mín 5, máx 50
  int _calcularHormigasolesPremio(double montoObjetivo) {
    final base = (montoObjetivo / 10).floor();
    return base.clamp(5, 50);
  }

  // Eliminar meta con confirmación
  Future<void> _confirmarEliminarMeta(Goal meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Eliminar meta?',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        content: Text(
          '¿Seguro que deseas eliminar "${meta.titulo}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.fredoka(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('Eliminar', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.deleteGoal(meta.id!);
      // Remove from claimed set too
      _reclamados.remove(meta.id);
      await _guardarReclamados();
      await _cargarMetas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meta "${meta.titulo}" eliminada',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.yellow,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Metas',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón para crear nueva meta
            ElevatedButton.icon(
              onPressed: () async {
                final creado = await _mostrarDialogoCrearMeta();
                if (creado == true) await _cargarMetas();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                'Crear Nueva Meta',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_cargando)
              const Center(child: CircularProgressIndicator())
            else if (_metas.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes metas aún',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primera meta arriba para comenzar',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _metas.length,
                itemBuilder: (context, index) {
                  final meta = _metas[index];
                  final esCompleta = meta.estaCompleta;
                  final yaReclamado = _reclamados.contains(meta.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Título + Badge + Eliminar
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  meta.titulo,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ),
                              if (esCompleta)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    yaReclamado ? '✅ Completada' : 'Completada',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              // Botón eliminar
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed, size: 22),
                                tooltip: 'Eliminar meta',
                                onPressed: () => _confirmarEliminarMeta(meta),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progreso
                          Row(
                            children: [
                              Text(
                                'Progreso: ',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: meta.progresoPorcentaje / 100,
                                    minHeight: 8,
                                    backgroundColor: AppColors.softTeal,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      esCompleta ? AppColors.teal : AppColors.darkBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Monto actual / objetivo
                          Text(
                            meta.progresoFormato,
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              color: AppColors.darkBlue,
                            ),
                          ),

                          // Descripción
                          if (meta.descripcion.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                meta.descripcion,
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Acciones
                          if (!esCompleta)
                            ElevatedButton.icon(
                              onPressed: () => _mostrarDialogoAgregarIngreso(meta),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.softTeal,
                                foregroundColor: AppColors.darkBlue,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                              label: Text(
                                'Agregar Ingreso',
                                style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            )
                          else if (!yaReclamado)
                            // Solo mostrar botón reclamar si NO se ha reclamado aún
                            ElevatedButton.icon(
                              onPressed: () async {
                                final hormigasolesPremio = _calcularHormigasolesPremio(meta.montoObjetivo);
                                await _gamif.ganarHormigasoles(hormigasolesPremio, motivo: 'Meta completada');

                                setState(() {
                                  _reclamados.add(meta.id!);
                                });
                                await _guardarReclamados();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🎉 ¡Has reclamado $hormigasolesPremio hormigasoles por completar "${meta.titulo}"!',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkBlue,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.softTeal,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.emoji_events_rounded),
                              label: Text(
                                'Reclamar Hormigasoles',
                                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            // Ya reclamado: mostrar mensaje
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.softTeal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hormigasoles reclamados ✅',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
