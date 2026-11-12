import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// En web SQLite corre compilado a WebAssembly (sqlite3.wasm) dentro de un
/// shared worker y los datos se guardan en IndexedDB.
void setupDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
