import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Notificacion detectada por el servicio nativo de Android.
class DetectedNotification {
  final String packageName;
  final String title;
  final String text;
  final DateTime timestamp;

  const DetectedNotification({
    required this.title,
    required this.text,
    required this.timestamp,
    this.packageName = '',
  });

  /// True si la notificacion proviene de un cliente de correo (Gmail, Outlook).
  bool get esCorreo {
    return packageName == 'com.google.android.gm' ||
        packageName == 'com.microsoft.office.outlook' ||
        packageName == 'com.google.android.email';
  }

  /// True si la notificacion proviene de una billetera Plin (Interbank, Tunki).
  bool get esPlin {
    return packageName == 'pe.com.interbank.mobilebanking' ||
        packageName == 'pe.indigital.tunki.user';
  }

  /// Origen que se guarda en la transaccion.
  String get origen {
    if (esCorreo) return 'email';
    if (esPlin) return 'plin';
    if (packageName == 'com.bcp.innovacxion.yapeapp' ||
        packageName == 'com.bcp.innovacxion.yape' ||
        packageName.isEmpty) {
      return 'yape';
    }
    return 'banco';
  }

  factory DetectedNotification.fromMap(Map<dynamic, dynamic> map) {
    final millis = (map['timestamp'] as num?)?.toInt();
    return DetectedNotification(
      packageName: (map['package'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      timestamp: millis != null
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : DateTime.now(),
    );
  }
}

/// Servicio para manejar la lectura de notificaciones Android.
///
/// En Android se apoya en `AhorrantNotificationService` (Kotlin) mediante un
/// MethodChannel. En otras plataformas o sin plugin disponible devuelve
/// valores seguros (sin permisos / sin notificaciones).
class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.ahorrant/notifications');

  static final StreamController<DetectedNotification> _controller =
      StreamController<DetectedNotification>.broadcast();
  static bool _handlerConfigured = false;

  /// Stream de notificaciones detectadas mientras la app esta activa.
  static Stream<DetectedNotification> get stream {
    _configurarHandler();
    return _controller.stream;
  }

  static void _configurarHandler() {
    if (_handlerConfigured) return;
    _handlerConfigured = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotification' && call.arguments is Map) {
        _controller.add(
          DetectedNotification.fromMap(call.arguments as Map<dynamic, dynamic>),
        );
      }
      return null;
    });
  }

  /// Verifica si el usuario ya concedio acceso a las notificaciones.
  static Future<bool> hayPermisos() async {
    _configurarHandler();
    try {
      final granted = await _channel.invokeMethod<bool>('isAccessGranted');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Error al verificar permisos: ${e.message}');
      return false;
    }
  }

  /// Abre la pantalla del sistema para conceder acceso a las notificaciones.
  static Future<bool> solicitarPermisos() async {
    _configurarHandler();
    if (await hayPermisos()) return true;
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Error al abrir ajustes de notificaciones: ${e.message}');
      return false;
    }
    return false;
  }

  /// Recupera las notificaciones pendientes almacenadas por el servicio nativo.
  static Future<List<DetectedNotification>> obtenerPendientes() async {
    _configurarHandler();
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getPendingNotifications');
      if (result == null) return const [];
      return result
          .whereType<Map<dynamic, dynamic>>()
          .map(DetectedNotification.fromMap)
          .toList();
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      debugPrint('Error al leer notificaciones pendientes: ${e.message}');
      return const [];
    }
  }

  /// Procesar una notificacion detectada y extraer monto, tipo y descripcion.
  static Map<String, dynamic>? procesarNotificacion(
      String titulo, String cuerpo) {
    try {
      final monto = _extraerMonto(cuerpo) ?? _extraerMonto(titulo);
      if (monto == null) return null;

      final tipo = _determinarTipo(titulo, cuerpo);
      return {
        'monto': monto,
        'tipo': tipo, // 'ingreso' o 'egreso'
        'titulo': titulo,
        'descripcion': cuerpo,
        'fecha': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error procesando notificacion: $e');
      return null;
    }
  }

  /// Extraer monto del texto de la notificacion.
  static double? _extraerMonto(String texto) {
    // Formatos como "S/ 8.00", "S/8.00", "S/. 8,00" o "S/ 1,250.00".
    final regex = RegExp(r'S\/\.?\s*([\d]+(?:[.,]\d{1,2})?)');
    final match = regex.firstMatch(texto);
    if (match == null) return null;
    final montoTexto = (match.group(1) ?? '').replaceAll(',', '.');
    try {
      return double.parse(montoTexto);
    } catch (e) {
      return null;
    }
  }

  /// Determinar si es ingreso o egreso basandose en el titulo y cuerpo.
  static String _determinarTipo(String titulo, String cuerpo) {
    final textoCompleto = '$titulo $cuerpo'.toLowerCase();

    final palabrasIngreso = [
      'recibiste',
      'recibido',
      'te ha plineado',
      'te han plineado',
      'te plineo',
      'te plineó',
      'plineado',
      'te yapearon',
      'te yapeo',
      'te yapeó',
      'te enviaron',
      'te envio',
      'te envió',
      'transferencia recibida',
      'abono',
      'deposito',
      'depósito',
      'bono',
      'regalo',
      'regaló',
      'ingreso',
    ];

    final palabrasEgreso = [
      'plineaste',
      'has plineado',
      'yapeaste',
      'pagaste',
      'pago',
      'enviaste',
      'envío',
      'envio',
      'gastaste',
      'gastó',
      'gasto',
      'compraste',
      'compró',
      'compra',
      'consumo',
      'retiro',
      'cargo',
      'transferencia',
      'pagó',
    ];

    // El ingreso tiene prioridad: "te yapearon" no debe leerse como egreso.
    if (palabrasIngreso.any(textoCompleto.contains)) {
      return 'ingreso';
    }
    if (palabrasEgreso.any(textoCompleto.contains)) {
      return 'egreso';
    }

    // Por defecto se asume egreso si el texto menciona un monto.
    return 'egreso';
  }
}
