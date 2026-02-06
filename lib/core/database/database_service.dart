import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

/// 数据库服务
class DatabaseService {
  static const String _dbName = 'margin.db';
  static const int _dbVersion = 1;

  Database? _database;
  final Logger _logger = Logger();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _logger.i('Initializing database at: $path');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables...');

    // 资产表
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('stock', 'bond')),
        source TEXT NOT NULL,
        encrypted_amount TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 再平衡记录表
    await db.execute('''
      CREATE TABLE rebalances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_ratio REAL NOT NULL CHECK(stock_ratio >= 0 AND stock_ratio <= 1),
        bond_ratio REAL NOT NULL CHECK(bond_ratio >= 0 AND bond_ratio <= 1),
        total_amount REAL NOT NULL CHECK(total_amount >= 0),
        stock_amount REAL NOT NULL CHECK(stock_amount >= 0),
        bond_amount REAL NOT NULL CHECK(bond_amount >= 0),
        target_stock_ratio REAL NOT NULL CHECK(target_stock_ratio >= 0 AND target_stock_ratio <= 1),
        target_bond_ratio REAL NOT NULL CHECK(target_bond_ratio >= 0 AND target_bond_ratio <= 1),
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 配置表
    await db.execute('''
      CREATE TABLE configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 来源表
    await db.execute('''
      CREATE TABLE sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_assets_type ON assets(type)');
    await db.execute('CREATE INDEX idx_assets_source ON assets(source)');
    await db.execute('CREATE INDEX idx_rebalances_created_at ON rebalances(created_at)');

    _logger.i('Database tables created successfully');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');
    // 处理数据库迁移
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.i('Database closed');
    }
  }

  /// 在事务中执行操作
  Future<T> executeInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        return await action(txn);
      });
    } catch (e) {
      _logger.e('Transaction failed: $e');
      rethrow;
    }
  }
}
