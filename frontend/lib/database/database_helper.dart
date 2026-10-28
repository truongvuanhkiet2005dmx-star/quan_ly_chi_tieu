import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_money_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        balance INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL,
        accountNumber TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        walletId INTEGER,
        toWalletId INTEGER,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        isExpense INTEGER NOT NULL,
        categoryName TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        eventId TEXT,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (walletId) REFERENCES wallets(id),
        FOREIGN KEY (toWalletId) REFERENCES wallets(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        targetAmount INTEGER NOT NULL,
        currentAmount INTEGER NOT NULL DEFAULT 0,
        colorHex TEXT,
        date TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          name TEXT NOT NULL,
          balance INTEGER NOT NULL DEFAULT 0,
          type TEXT NOT NULL
        )
      ''');

      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN userId INTEGER NOT NULL DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN walletId INTEGER
      ''');

      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN toWalletId INTEGER
      ''');

      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'
      ''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('''
          ALTER TABLE wallets
          ADD COLUMN accountNumber TEXT
        ''');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          name TEXT NOT NULL,
          targetAmount INTEGER NOT NULL,
          currentAmount INTEGER NOT NULL DEFAULT 0,
          colorHex TEXT,
          date TEXT,
          FOREIGN KEY (userId) REFERENCES users(id)
        )
      ''');
    }

    if (oldVersion < 4) {
      try {
        await db.execute('''
          ALTER TABLE transactions
          ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0
        ''');
      } catch (_) {}

      try {
        await db.execute('''
          ALTER TABLE transactions
          ADD COLUMN eventId TEXT
        ''');
      } catch (_) {}
    }
  }

  Future<int> registerUser(
      String username,
      String password,
      ) async {
    final db = await instance.database;

    return await db.insert(
      'users',
      {
        'username': username,
        'password': password,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> loginUser(
      String username,
      String password,
      ) async {
    final db = await instance.database;

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await instance.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> insertWallet(
      Map<String, dynamic> wallet,
      ) async {
    final db = await instance.database;

    return await db.insert(
      'wallets',
      wallet,
    );
  }

  Future<List<Map<String, dynamic>>> getWallets(
      int userId,
      ) async {
    final db = await instance.database;

    return await db.query(
      'wallets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, dynamic>?> getWalletById(
      int walletId,
      ) async {
    final db = await instance.database;

    final result = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [walletId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateWalletBalance(
      int walletId,
      int newBalance,
      ) async {
    final db = await instance.database;

    return await db.update(
      'wallets',
      {
        'balance': newBalance,
      },
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  Future<int> updateWallet(
      int walletId,
      Map<String, dynamic> walletData,
      ) async {
    final db = await instance.database;

    return await db.update(
      'wallets',
      walletData,
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  Future<int> deleteWallet(
      int walletId,
      ) async {
    final db = await instance.database;

    return await db.delete(
      'wallets',
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  Future<int> insertSavingsGoal(
      Map<String, dynamic> goal,
      ) async {
    final db = await instance.database;

    return await db.insert(
      'savings_goals',
      goal,
    );
  }

  Future<List<Map<String, dynamic>>> getSavingsGoals(
      int userId,
      ) async {
    final db = await instance.database;

    return await db.query(
      'savings_goals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

  Future<int> updateSavingsGoalAmount(
      int goalId,
      int newCurrentAmount,
      ) async {
    final db = await instance.database;

    return await db.update(
      'savings_goals',
      {
        'currentAmount': newCurrentAmount,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> deleteSavingsGoal(
      int goalId,
      ) async {
    final db = await instance.database;

    return await db.delete(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> insertTransaction(
      Map<String, dynamic> transaction,
      ) async {
    final db = await instance.database;

    final id = await db.insert(
      'transactions',
      transaction,
    );

    if (transaction['eventId'] == null || transaction['eventId'].toString().isEmpty) {
      final generatedEventId = 'tx_$id';
      await db.update(
        'transactions',
        {'eventId': generatedEventId},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    return id;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions(int userId) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'userId = ? AND (isSynced IS NULL OR isSynced = 0)',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

  Future<void> markTransactionSynced(int id) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions(
      int userId,
      ) async {
    final db = await instance.database;

    return await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDate(
      int userId,
      String date,
      ) async {
    final db = await instance.database;

    return await db.query(
      'transactions',
      where: 'userId = ? AND date LIKE ?',
      whereArgs: [userId, '$date%'],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByType(
      int userId,
      String type,
      ) async {
    final db = await instance.database;

    return await db.query(
      'transactions',
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<int> getTotalBalance(
      int userId,
      ) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT SUM(balance) AS total
      FROM wallets
      WHERE userId = ?
    ''', [userId]);

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalIncome(
      int userId,
      ) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE userId = ?
      AND type = 'income'
    ''', [userId]);

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalExpense(
      int userId,
      ) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE userId = ?
      AND type = 'expense'
    ''', [userId]);

    return (result.first['total'] as int?) ?? 0;
  }
}