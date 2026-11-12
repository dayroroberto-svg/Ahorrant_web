import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/goal_model.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._internal();

  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  Database? _database;

  static const int _versionBaseDeDatos = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // En web el "path" es solo un nombre (la base se guarda en IndexedDB);
    // getDatabasesPath() devuelve '/' en web y la carpeta de bases en movil.
    final String path = join(await getDatabasesPath(), 'ahorrant.db');

    // Crear o abrir la base de datos con versión actualizada
    var db = await openDatabase(
      path,
      version: _versionBaseDeDatos,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return db;
  }

  void _onCreate(Database db, int version) async {
    // Tabla de transacciones
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        origin TEXT NOT NULL,
        description TEXT,
        synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de metas
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        montoObjetivo REAL NOT NULL,
        montoActual REAL DEFAULT 0,
        categoria TEXT,
        fechaCreacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fechaVencimiento TEXT
      )
    ''');
  }

  // INSERTAR una transacción
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  // OBTENER todas las transacciones
  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // OBTENER transacciones no sincronizadas
  Future<List<Transaction>> getUnsyncedTransactions() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // ACTUALIZAR una transacción (marcar como sincronizada)
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ELIMINAR una transacción
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Contar total de transacciones
  Future<int> getTransactionCount() async {
    final db = await instance.database;
    var result = await db.rawQuery('SELECT COUNT(*) FROM transactions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Métodos para Metas ---

  // INSERTAR una meta
  Future<int> insertGoal(Goal goal) async {
    final db = await instance.database;
    return await db.insert('goals', goal.toMap());
  }

  // OBTENER todas las metas
  Future<List<Goal>> getAllGoals() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('goals', orderBy: 'fechaCreacion DESC');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  // ACTUALIZAR una meta (usada para sumar montoActual)
  Future<int> updateGoal(Goal goal) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // ELIMINAR una meta
  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Contar total de metas
  Future<int> getGoalCount() async {
    final db = await instance.database;
    var result = await db.rawQuery('SELECT COUNT(*) FROM goals');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Migrar la base de datos cuando la versión cambie
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ejecutar creación de tabla goals si no existe (migración para usuarios que venían de versiones anteriores)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        montoObjetivo REAL NOT NULL,
        montoActual REAL DEFAULT 0,
        categoria TEXT,
        fechaCreacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fechaVencimiento TEXT
      )
    ''');
    
    // Si la tabla goals ya existía pero con esquema antiguo, no hace falta alterar aquí
    // la tabla ya será usada tal como quedó creada en _onCreate o en upgrades previos
  }

  // Cerrar base de datos
  Future close() async {
    final db = await instance.database;
    return db.close();
  }
}
