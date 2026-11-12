import 'package:flutter/material.dart';

class ArticuloTienda {
  final String id;
  final String nombre;
  final int precio;
  final IconData icono;
  final String descripcion;

  const ArticuloTienda({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.icono,
    required this.descripcion,
  });

  static const List<ArticuloTienda> catalogo = [
    ArticuloTienda(
      id: 'sombrero',
      nombre: 'Sombrero de explorador',
      precio: 50,
      icono: Icons.explore_rounded,
      descripcion: 'Para explorar nuevos senderos y descubrir formas de ahorrar.',
    ),
    ArticuloTienda(
      id: 'mochila',
      nombre: 'Mochila aventurera',
      precio: 80,
      icono: Icons.backpack_rounded,
      descripcion: 'Carga tus sueños y metas universitarias a donde vayas.',
    ),
    ArticuloTienda(
      id: 'gafas',
      nombre: 'Gafas de sol',
      precio: 40,
      icono: Icons.wb_sunny_rounded,
      descripcion: 'Para ver tu brillante futuro financiero con todo el estilo.',
    ),
  ];
}

