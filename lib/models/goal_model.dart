class Goal {
  final int? id;
  final String titulo;
  final String descripcion;
  final double montoObjetivo;
  double montoActual;
  final String categoria;
  final DateTime fechaCreacion;
  final DateTime? fechaVencimiento;

  Goal({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.montoObjetivo,
    this.montoActual = 0.0,
    required this.categoria,
    DateTime? fechaCreacion,
    this.fechaVencimiento,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Calcula el porcentaje de progreso
  double get progresoPorcentaje {
    if (montoObjetivo == 0) return 0.0;
    return ((montoActual / montoObjetivo) * 100).clamp(0.0, 100.0);
  }

  // Verifica si la meta está completada
  bool get estaCompleta => progresoPorcentaje >= 100.0;

  // Formatea el monto actual / objetivo
  String get progresoFormato => '${montoActual.toStringAsFixed(2)} / ${montoObjetivo.toStringAsFixed(2)}';

  // String para display del progreso
  String get progresoString => '${progresoPorcentaje.toStringAsFixed(0)}%';

  // Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'montoObjetivo': montoObjetivo,
      'montoActual': montoActual,
      'categoria': categoria,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
    };
  }

  // Crear desde Map (al leer de SQLite)
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      montoObjetivo: (map['montoObjetivo'] as num).toDouble(),
      montoActual: (map['montoActual'] as num).toDouble(),
      categoria: map['categoria'] as String,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      fechaVencimiento:
          map['fechaVencimiento'] != null
              ? DateTime.parse(map['fechaVencimiento'] as String)
              : null,
    );
  }

  // Copiar la meta cambiando solo los campos indicados
  Goal copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    double? montoObjetivo,
    double? montoActual,
    String? categoria,
    DateTime? fechaCreacion,
    DateTime? fechaVencimiento,
  }) {
    return Goal(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      montoObjetivo: montoObjetivo ?? this.montoObjetivo,
      montoActual: montoActual ?? this.montoActual,
      categoria: categoria ?? this.categoria,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    );
  }
}