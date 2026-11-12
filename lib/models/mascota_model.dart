import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum EstadoMascota {
  feliz,
  motivada,
  descansando,
  animada;

  String get titulo {
    switch (this) {
      case EstadoMascota.feliz:
        return 'Feliz';
      case EstadoMascota.motivada:
        return 'Motivada';
      case EstadoMascota.descansando:
        return 'Descansando';
      case EstadoMascota.animada:
        return 'Animada';
    }
  }

  String get emoji {
    switch (this) {
      case EstadoMascota.feliz:
        return '😊';
      case EstadoMascota.motivada:
        return '🔥';
      case EstadoMascota.descansando:
        return '😴';
      case EstadoMascota.animada:
        return '🎉';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoMascota.feliz:
        return '¡Cumpliendo tus metas financieras y cuidando tus gastos!';
      case EstadoMascota.motivada:
        return '¡Mantienes una racha imparable de ahorro universitario!';
      case EstadoMascota.descansando:
        return 'Tomando una siesta en el túnel. ¡Registra un movimiento para activarla!';
      case EstadoMascota.animada:
        return '¡Celebrando recompensas y subiendo de nivel en el hormiguero!';
    }
  }

  Color get colorFondo {
    switch (this) {
      case EstadoMascota.feliz:
        return AppColors.softTeal;
      case EstadoMascota.motivada:
        return AppColors.softYellow;
      case EstadoMascota.descansando:
        return AppColors.softCyan;
      case EstadoMascota.animada:
        return const Color(0xFFF3E8FF);
    }
  }

  Color get colorAcento {
    switch (this) {
      case EstadoMascota.feliz:
        return AppColors.teal;
      case EstadoMascota.motivada:
        return AppColors.yellow;
      case EstadoMascota.descansando:
        return AppColors.cyan;
      case EstadoMascota.animada:
        return Colors.purple;
    }
  }
}

