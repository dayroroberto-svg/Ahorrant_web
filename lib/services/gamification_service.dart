import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/articulo_tienda.dart';
import '../models/mascota_model.dart';
import '../models/registro_hormigasoles.dart';

class GamificationService extends ChangeNotifier {
  static final GamificationService instance = GamificationService._internal();

  GamificationService._internal();

  // Original fields
  int _hormigasoles = 60;
  int _rachaDias = 0;
  int _nivelHormiguero = 1;
  int _xp = 0;
  DateTime? _ultimaReclamacion;
  DateTime? _ultimoRegistroGasto;
  bool _inicializado = false;
  final Set<String> _inventario = {};
  final Set<String> _equipados = {};
  EstadoMascota _estado = EstadoMascota.feliz;

  // Totales acumulados (para el modulo Progreso)
  int _hormigasolesObtenidos = 0;
  int _hormigasolesGastados = 0;
  final List<RegistroHormigasoles> _historial = [];

  // Claves de almacenamiento
  static const String _kHs = 'gamif_hs';
  static const String _kRacha = 'gamif_racha';
  static const String _kNivel = 'gamif_nivel';
  static const String _kXp = 'gamif_xp';
  static const String _kUltimaReclamacion = 'gamif_ultima_reclamacion';
  static const String _kUltimoRegistroGasto = 'gamif_ultimo_registro_gasto';
  static const String _kInventario = 'gamif_inventario';
  static const String _kEquipados = 'gamif_equipados';
  static const String _kEstado = 'gamif_estado';
  static const String _kHsObtenidos = 'gamif_hs_obtenidos';
  static const String _kHsGastados = 'gamif_hs_gastados';
  static const String _kHistorial = 'gamif_historial_hs';

  static const int _maximoHistorial = 500;

  // Original getters
  int get hormigasoles => _hormigasoles;
  int get rachaDias => _rachaDias;
  int get nivelHormiguero => _nivelHormiguero;
  int get xp => _xp;
  DateTime? get ultimaReclamacion => _ultimaReclamacion;
  DateTime? get ultimoRegistroGasto => _ultimoRegistroGasto;
  bool get inicializado => _inicializado;

  // Totales acumulados e historial
  int get hormigasolesObtenidos => _hormigasolesObtenidos;
  int get hormigasolesGastados => _hormigasolesGastados;
  List<RegistroHormigasoles> get historial =>
      List.unmodifiable(_historial);

  // Original level name
  String get nombreNivel {
    switch (_nivelHormiguero) {
      case 1:
        return 'Hormiguero Inicial';
      case 2:
        return 'Hormiguero en Crecimiento';
      case 3:
        return 'Hormiguero Organizado';
      case 4:
        return 'Hormiguero Avanzado';
      default:
        return 'Hormiguero Desarrollado';
    }
  }

  double get progresoNivel => (_xp % 100) / 100.0;

  // Original inventory/equipment
  Set<String> get inventario => Set.unmodifiable(_inventario);
  Set<String> get equipados => Set.unmodifiable(_equipados);
  bool estaComprado(String articuloId) => _inventario.contains(articuloId);
  bool estaEquipado(String articuloId) => _equipados.contains(articuloId);

  // Original pet state
  EstadoMascota get estado => _estado;
  cambiarEstado(EstadoMascota nuevoEstado) async {
    _estado = nuevoEstado;
    await _guardar();
    notifyListeners();
  }

  acariciarMascota() async {
    _hormigasoles += 2;
    _xp += 5;
    _hormigasolesObtenidos += 2;
    _registrarMovimiento(2, 'acariciar a la hormiga');
    _estado = EstadoMascota.animada;
    await _guardar();
    notifyListeners();
  }

  // Original store methods
  Future<bool> comprarArticulo(ArticuloTienda articulo) async {
    if (_inventario.contains(articulo.id)) {
      // Ya comprado: no se cobra dos veces
      return true;
    }
    if (_hormigasoles < articulo.precio) {
      return false;
    }
    _hormigasoles -= articulo.precio;
    _hormigasolesGastados += articulo.precio;
    _registrarMovimiento(-articulo.precio, 'Compra: ${articulo.nombre}');
    _inventario.add(articulo.id);
    _equipados.add(articulo.id);
    _estado = EstadoMascota.animada;
    _xp += 15;
    await _guardar();
    notifyListeners();
    return true;
  }

  Future<void> alternarEquipado(String articuloId) async {
    if (!_inventario.contains(articuloId)) return;

    if (_equipados.contains(articuloId)) {
      _equipados.remove(articuloId);
    } else {
      _equipados.add(articuloId);
      _estado = EstadoMascota.feliz;
    }
    await _guardar();
    notifyListeners();
  }

  /// Indica si el objetivo diario ya fue reclamado hoy.
  bool get objetivoDiarioReclamadoHoy {
    final ahora = DateTime.now();
    final ultima = _ultimaReclamacion;
    if (ultima == null) return false;
    return ultima.year == ahora.year &&
        ultima.month == ahora.month &&
        ultima.day == ahora.day;
  }

  /// El objetivo diario solo se puede reclamar una vez por dia.
  bool get puedeReclamarObjetivoDiario => !objetivoDiarioReclamadoHoy;

  /// Verifica si se puede reclamar el objetivo diario y lo reclama si es posible
  /// Retorna true si se reclamó, false si ya se reclamó hoy
  Future<bool> tentarObjetivoDiario() async {
    final ahora = DateTime.now();

    // Si ya se reclamo hoy, no permite reclamar nuevamente.
    if (objetivoDiarioReclamadoHoy) {
      return false;
    }

    // Se marca de forma sincrona ANTES de esperar, para evitar que dos
    // pulsaciones rapidas del boton tauren dos veces.
    _ultimaReclamacion = ahora;

    // Reclamar objetivo diario: +10 HS y +20 XP
    await _sumarHormigasoles(10, motivo: 'Objetivo diario');
    await _guardar();
    notifyListeners();
    return true;
  }

  /// Añade Hormigasoles y XP por registrar un gasto hormiga
  Future<void> registrarGastoHormiga() async {
    // Award 5 HS and 10 XP per gasto hormiga
    await _sumarHormigasoles(5, motivo: 'Gasto hormiga registrado');
    // Additional 5 XP to reach total of 15 XP
    _xp += 5;
    // Incrementar la racha
    await _incrementarRacha();
    notifyListeners();
  }

  /// Incrementa la racha al registrar un gasto hormiga
  Future<void> _incrementarRacha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ultimoRegistroHoy =
        _ultimoRegistroGasto != null
            ? DateTime(_ultimoRegistroGasto!.year, _ultimoRegistroGasto!.month,
                _ultimoRegistroGasto!.day)
            : null;

    // Si ya registro hoy, no incrementa la racha (se mantiene)
    if (ultimoRegistroHoy != null && ultimoRegistroHoy == hoy) {
      return;
    }

    // Primera vez o hace más de 24 horas: reinicia la racha a 1
    if (_ultimoRegistroGasto == null) {
      _rachaDias = 1;
    } else {
      final diferencia = ahora.difference(_ultimoRegistroGasto!).inHours;
      if (diferencia > 24) {
        _rachaDias = 1;
      } else {
        // Continuar la racha
        _rachaDias = _rachaDias + 1;
      }
    }

    _ultimoRegistroGasto = ahora;
    await _guardar();
    notifyListeners();
  }

  /// Método interno para sumar hormigasoles y XP y subir nivel
  Future<void> _sumarHormigasoles(int cantidad, {required String motivo}) async {
    _hormigasoles += cantidad;
    _xp += cantidad * 2;

    // Subida de nivel cada 100 XP
    final nuevoNivel = 1 + (_xp ~/ 100);
    if (nuevoNivel > _nivelHormiguero) {
      _nivelHormiguero = nuevoNivel;
    }

    _hormigasolesObtenidos += cantidad;
    _registrarMovimiento(cantidad, motivo);

    await _guardar();
    notifyListeners();
  }

  /// Registra un movimiento de Hormigasoles en el historial diario.
  void _registrarMovimiento(int cantidad, String motivo) {
    _historial.add(RegistroHormigasoles(
      fecha: DateTime.now(),
      cantidad: cantidad,
      motivo: motivo,
    ));
    if (_historial.length > _maximoHistorial) {
      _historial.removeRange(0, _historial.length - _maximoHistorial);
    }
  }

  // Original public method that other screens use
  Future<void> ganarHormigasoles(int cantidad, {required String motivo}) async {
    await _sumarHormigasoles(cantidad, motivo: motivo);
  }

  // Original initialization and saving
  Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hormigasoles = prefs.getInt(_kHs) ?? 60;
      _rachaDias = prefs.getInt(_kRacha) ?? 0;
      _nivelHormiguero = prefs.getInt(_kNivel) ?? 1;
      _xp = prefs.getInt(_kXp) ?? 0;
      _hormigasolesObtenidos = prefs.getInt(_kHsObtenidos) ?? 0;
      _hormigasolesGastados = prefs.getInt(_kHsGastados) ?? 0;

      final reklamacion = prefs.getString(_kUltimaReclamacion);
      if (reklamacion != null && reklamacion.isNotEmpty) {
        _ultimaReclamacion = DateTime.tryParse(reklamacion);
      }

      final ultimoRegistro = prefs.getString(_kUltimoRegistroGasto);
      if (ultimoRegistro != null && ultimoRegistro.isNotEmpty) {
        _ultimoRegistroGasto = DateTime.tryParse(ultimoRegistro);
      }

      // Inventario de articulos comprados (evita que se pierdan al cerrar la app)
      _inventario
        ..clear()
        ..addAll(prefs.getStringList(_kInventario) ?? const <String>[]);

      _equipados
        ..clear()
        ..addAll(prefs.getStringList(_kEquipados) ?? const <String>[]);
      // Solo se pueden equipar articulos que esten comprados
      _equipados.removeWhere((id) => !_inventario.contains(id));

      final estadoGuardado = prefs.getString(_kEstado);
      _estado = EstadoMascota.values.firstWhere(
        (e) => e.name == estadoGuardado,
        orElse: () => EstadoMascota.feliz,
      );

      // Historial de movimientos de Hormigasoles
      _historial.clear();
      final historialCrudo = prefs.getString(_kHistorial);
      if (historialCrudo != null && historialCrudo.isNotEmpty) {
        try {
          final lista = jsonDecode(historialCrudo) as List<dynamic>;
          for (final item in lista) {
            _historial.add(
                RegistroHormigasoles.fromMap(Map<String, dynamic>.from(item as Map)));
          }
        } catch (e) {
          debugPrint('No se pudo leer el historial de Hormigasoles: $e');
        }
      } else {
        // Primera vez que se registra el historial: se toma el saldo actual
        // como "saldo inicial" para que los totales no queden en cero.
        if (_hormigasolesObtenidos == 0 && _hormigasolesGastados == 0) {
          _hormigasolesObtenidos = _hormigasoles;
          if (_hormigasoles > 0) {
            _historial.add(RegistroHormigasoles(
              fecha: DateTime.now(),
              cantidad: _hormigasoles,
              motivo: 'Saldo inicial',
            ));
          }
        }
      }

      _inicializado = true;
      notifyListeners();
      await _guardar();
    } catch (e) {
      debugPrint('Error al inicializar GamificationService: $e');
    }
  }

  Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kHs, _hormigasoles);
      await prefs.setInt(_kRacha, _rachaDias);
      await prefs.setInt(_kNivel, _nivelHormiguero);
      await prefs.setInt(_kXp, _xp);
      await prefs.setInt(_kHsObtenidos, _hormigasolesObtenidos);
      await prefs.setInt(_kHsGastados, _hormigasolesGastados);
      await prefs.setString(_kUltimaReclamacion,
          _ultimaReclamacion?.toIso8601String() ?? '');
      await prefs.setString(_kUltimoRegistroGasto,
          _ultimoRegistroGasto?.toIso8601String() ?? '');

      // Inventario y estado de la mascota (persisten entre sesiones)
      await prefs.setStringList(_kInventario, _inventario.toList());
      await prefs.setStringList(_kEquipados, _equipados.toList());
      await prefs.setString(_kEstado, _estado.name);

      await prefs.setString(
        _kHistorial,
        jsonEncode(_historial.map((r) => r.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error al guardar datos de GamificationService: $e');
    }
  }
}
