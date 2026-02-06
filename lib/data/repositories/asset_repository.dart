import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../models/asset.dart';
import '../../core/database/database_service.dart';

/// 资产仓库异常
class AssetRepositoryException implements Exception {
  final String message;
  AssetRepositoryException(this.message);

  @override
  String toString() => message;
}

/// 资产仓库
class AssetRepository {
  final DatabaseService _dbService;
  final Logger _logger = Logger();

  AssetRepository(this._dbService);

  /// 查询所有资产
  Future<List<Asset>> findAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'assets',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Asset.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to find all assets: $e');
      throw AssetRepositoryException('获取资产列表失败');
    }
  }

  /// 根据 ID 查询资产
  Future<Asset?> findById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'assets',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return Asset.fromMap(maps.first);
    } catch (e) {
      _logger.e('Failed to find asset by id: $e');
      throw AssetRepositoryException('获取资产失败');
    }
  }

  /// 根据类型查询资产
  Future<List<Asset>> findByType(AssetType type) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'assets',
        where: 'type = ?',
        whereArgs: [type.value],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Asset.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to find assets by type: $e');
      throw AssetRepositoryException('获取资产列表失败');
    }
  }

  /// 根据来源查询资产
  Future<List<Asset>> findBySource(String source) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'assets',
        where: 'source = ?',
        whereArgs: [source],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Asset.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to find assets by source: $e');
      throw AssetRepositoryException('获取资产列表失败');
    }
  }

  /// 创建资产
  Future<Asset> create(Asset asset) async {
    try {
      final db = await _dbService.database;
      final id = await db.insert(
        'assets',
        asset.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return asset.copyWith(id: id);
    } catch (e) {
      _logger.e('Failed to create asset: $e');
      throw AssetRepositoryException('创建资产失败');
    }
  }

  /// 更新资产
  Future<void> update(Asset asset) async {
    if (asset.id == null) {
      throw AssetRepositoryException('资产 ID 不能为空');
    }

    try {
      final db = await _dbService.database;
      final count = await db.update(
        'assets',
        asset.toMap(),
        where: 'id = ?',
        whereArgs: [asset.id],
      );

      if (count == 0) {
        throw AssetRepositoryException('资产不存在');
      }
    } catch (e) {
      _logger.e('Failed to update asset: $e');
      throw AssetRepositoryException('更新资产失败');
    }
  }

  /// 删除资产
  Future<void> delete(int id) async {
    try {
      final db = await _dbService.database;
      final count = await db.delete(
        'assets',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw AssetRepositoryException('资产不存在');
      }
    } catch (e) {
      _logger.e('Failed to delete asset: $e');
      throw AssetRepositoryException('删除资产失败');
    }
  }
}
