import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/transaction_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cashflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        gameType TEXT,
        success INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        description TEXT,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions(
    String userId, {
    String? filterType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final db = await instance.database;

    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (filterType != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(filterType);
    }

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
