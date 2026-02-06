import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../models/source.dart';
import '../../core/database/database_service.dart';

/// 来源仓库
class SourceRepository {
  final DatabaseService _dbService;
  final Logger _logger = Logger();

  SourceRepository(this._dbService);

  /// 查询所有来源
  Future<List<Source>> findAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sources',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Source.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to find all sources: $e');
      return [];
    }
  }

  /// 根据 ID 查询来源
  Future<Source?> findById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sources',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return Source.fromMap(maps.first);
    } catch (e) {
      _logger.e('Failed to find source by id: $e');
      return null;
    }
  }

  /// 创建来源
  Future<Source> create(Source source) async {
    try {
      final db = await _dbService.database;
      final id = await db.insert(
        'sources',
        source.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return Source(
        id: id,
        name: source.name,
        createdAt: source.createdAt,
      );
    } catch (e) {
      _logger.e('Failed to create source: $e');
      throw Exception('创建来源失败');
    }
  }

  /// 删除来源
  Future<void> delete(int id) async {
    // 检查是否被资产引用
    if (await isUsedByAssets(id)) {
      throw Exception('该来源正在被使用，无法删除');
    }

    try {
      final db = await _dbService.database;
      await db.delete(
        'sources',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.e('Failed to delete source: $e');
      throw Exception('删除来源失败');
    }
  }

  /// 检查来源是否被资产使用
  Future<bool> isUsedByAssets(int id) async {
    try {
      final db = await _dbService.database;
      final source = await findById(id);
      if (source == null) return false;

      final List<Map<String, dynamic>> maps = await db.query(
        'assets',
        where: 'source = ?',
        whereArgs: [source.name],
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to check if source is used: $e');
      return false;
    }
  }
}
