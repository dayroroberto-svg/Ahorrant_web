import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'database_helper.dart';

enum SyncStatus { ok, sinPendientes, noConfigurado, error }

class SyncResult {
  final SyncStatus status;
  final int enviados;
  final String mensaje;

  const SyncResult({
    required this.status,
    required this.enviados,
    required this.mensaje,
  });
}

/// Cola de sincronizacion de movimientos locales hacia el backend.
///
/// Los movimientos se guardan siempre en SQLite (fuente de verdad offline).
/// Cuando existe `AHORRANT_API_URL` configurado via `--dart-define`, se envian
/// los pendientes y se marcan como sincronizados. Sin backend configurado, la
/// cola permanece local y se reintenta en la proxima sincronizacion.
class SyncService {
  static const String _baseUrl = String.fromEnvironment('AHORRANT_API_URL');

  static bool get configurado => _baseUrl.isNotEmpty;

  static Future<SyncResult> sincronizarPendientes() async {
    final db = DatabaseHelper.instance;
    final pendientes = await db.getUnsyncedTransactions();

    if (pendientes.isEmpty) {
      return const SyncResult(
        status: SyncStatus.sinPendientes,
        enviados: 0,
        mensaje: 'No hay movimientos pendientes de sincronizar.',
      );
    }

    if (!configurado) {
      return SyncResult(
        status: SyncStatus.noConfigurado,
        enviados: 0,
        mensaje:
            'Backend no configurado. ${pendientes.length} movimiento(s) quedan en cola local.',
      );
    }

    var enviados = 0;
    for (final transaccion in pendientes) {
      try {
        final respuesta = await http
            .post(
              Uri.parse('$_baseUrl/transactions'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(
                transaccion.copyWith(id: null).toMap()..remove('id'),
              ),
            )
            .timeout(const Duration(seconds: 10));

        if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
          await db.updateTransaction(transaccion.copyWith(synced: true));
          enviados++;
        } else {
          debugPrint(
            'Sync fallo (${respuesta.statusCode}): ${respuesta.body}',
          );
        }
      } catch (e) {
        debugPrint('Error sincronizando movimiento ${transaccion.id}: $e');
      }
    }

    if (enviados == 0) {
      return SyncResult(
        status: SyncStatus.error,
        enviados: 0,
        mensaje:
            'No se pudo sincronizar. ${pendientes.length} movimiento(s) siguen en cola local.',
      );
    }

    final restantes = pendientes.length - enviados;
    return SyncResult(
      status: SyncStatus.ok,
      enviados: enviados,
      mensaje: restantes == 0
          ? 'Sincronizados $enviados movimiento(s).'
          : 'Sincronizados $enviados movimiento(s). Quedan $restantes pendientes.',
    );
  }
}
