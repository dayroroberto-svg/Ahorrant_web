/// Registro de un movimiento de Hormigasoles (ganados o gastados).
/// Se usa para poder mostrar en el modulo Progreso cuanto se ha recaudado
/// por dia y filtrar por periodos.
class RegistroHormigasoles {
  final DateTime fecha;
  final int cantidad; // positivo = ganados, negativo = gastados
  final String motivo;

  const RegistroHormigasoles({
    required this.fecha,
    required this.cantidad,
    required this.motivo,
  });

  bool get esGasto => cantidad < 0;
  int get valorAbsoluto => cantidad.abs();

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'cantidad': cantidad,
      'motivo': motivo,
    };
  }

  factory RegistroHormigasoles.fromMap(Map<String, dynamic> map) {
    return RegistroHormigasoles(
      fecha: DateTime.parse(map['fecha'] as String),
      cantidad: (map['cantidad'] as num).toInt(),
      motivo: (map['motivo'] as String?) ?? '',
    );
  }

  @override
  String toString() =>
      'RegistroHormigasoles($cantidad HS, $motivo, ${fecha.toIso8601String()})';
}
