import 'package:flutter/material.dart';

/// Modelo de una microleccion con video de YouTube asociado.
class Clase {
  final int numero;
  final String titulo;
  final String descripcion;
  final String url;
  final IconData icono;

  const Clase({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.url,
    required this.icono,
  });

  /// Identificador del video de YouTube (se usa para mostrar la miniatura).
  String get videoId {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final id = uri.queryParameters['v'];
    if (id != null && id.isNotEmpty) return id;
    // Formato youtu.be/<id>
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) return segments.last;
    return '';
  }

  String get miniatura =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}
