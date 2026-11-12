class Transaction {
  final int? id;
  final double amount;
  final DateTime date;
  final String type; // 'ingreso' o 'egreso'
  final String category; // 'gastos hormiga', 'transporte', 'alimentacion', etc.
  final String? description;
  final bool synced; // Si ya se sincronizó con Supabase
  final String origin;

  const Transaction({
    this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.description,
    this.synced = false,
    this.origin = 'manual',
  });

  // Copiar la transaccion cambiando solo los campos indicados
  Transaction copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? type,
    String? category,
    String? description,
    bool? synced,
    String? origin,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      synced: synced ?? this.synced,
      origin: origin ?? this.origin,
    );
  }

  // Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'category': category,
      'description': description,
      'synced': synced ? 1 : 0,
      'origin': origin,
    };
  }

  // Crear desde Map (al leer de SQLite)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      synced: map['synced'] == 1,
      origin: map['origin'] as String? ?? 'manual',
    );
  }

  // Igualdad para comparar transacciones
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Transaction &&
        id == other.id &&
        amount == other.amount &&
        date == other.date &&
        type == other.type &&
        category == other.category &&
        description == other.description &&
        synced == other.synced &&
        origin == other.origin;
  }

  @override
  int get hashCode =>
      id.hashCode ^ amount.hashCode ^ date.hashCode ^ type.hashCode ^ category.hashCode ^ description.hashCode ^ synced.hashCode ^ origin.hashCode;
}