import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../models/config.dart';
import '../../core/database/database_service.dart';

/// 配置仓库
class ConfigRepository {
  final DatabaseService _dbService;
  final Logger _logger = Logger();

  ConfigRepository(this._dbService);

  /// 获取配置值
  Future<String?> getValue(ConfigKey key) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'configs',
        where: 'key = ?',
        whereArgs: [key.value],
      );

      if (maps.isEmpty) return null;
      return maps.first['value'] as String;
    } catch (e) {
      _logger.e('Failed to get config value: $e');
      return null;
    }
  }

  /// 设置配置值
  Future<void> setValue(ConfigKey key, String value) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now();

      await db.insert(
        'configs',
        {
          'key': key.value,
          'value': value,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.e('Failed to set config value: $e');
      rethrow;
    }
  }

  /// 删除配置
  Future<void> delete(ConfigKey key) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        'configs',
        where: 'key = ?',
        whereArgs: [key.value],
      );
    } catch (e) {
      _logger.e('Failed to delete config: $e');
      rethrow;
    }
  }

  /// 获取所有配置
  Future<Map<ConfigKey, String>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query('configs');

      final result = <ConfigKey, String>{};
      for (final map in maps) {
        final key = ConfigKey.fromString(map['key'] as String);
        result[key] = map['value'] as String;
      }

      return result;
    } catch (e) {
      _logger.e('Failed to get all configs: $e');
      return {};
    }
  }
}
