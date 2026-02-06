import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../models/rebalance.dart';
import '../../core/database/database_service.dart';

/// 再平衡仓库
class RebalanceRepository {
  final DatabaseService _dbService;
  final Logger _logger = Logger();

  RebalanceRepository(this._dbService);

  /// 查询所有再平衡记录
  Future<List<Rebalance>> findAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'rebalances',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Rebalance.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to find all rebalances: $e');
      return [];
    }
  }

  /// 根据 ID 查询再平衡记录
  Future<Rebalance?> findById(int id) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'rebalances',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return Rebalance.fromMap(maps.first);
    } catch (e) {
      _logger.e('Failed to find rebalance by id: $e');
      return null;
    }
  }

  /// 创建再平衡记录
  Future<Rebalance> create(Rebalance rebalance) async {
    try {
      final db = await _dbService.database;
      final id = await db.insert(
        'rebalances',
        rebalance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return Rebalance(
        id: id,
        stockRatio: rebalance.stockRatio,
        bondRatio: rebalance.bondRatio,
        totalAmount: rebalance.totalAmount,
        stockAmount: rebalance.stockAmount,
        bondAmount: rebalance.bondAmount,
        targetStockRatio: rebalance.targetStockRatio,
        targetBondRatio: rebalance.targetBondRatio,
        note: rebalance.note,
        createdAt: rebalance.createdAt,
      );
    } catch (e) {
      _logger.e('Failed to create rebalance: $e');
      throw Exception('创建再平衡记录失败');
    }
  }

  /// 根据日期范围查询
  Future<List<Rebalance>> findByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'rebalances',
        where: 'created_at BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => Rebalance.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to find rebalances by date range: $e');
      return [];
    }
  }

  /// 获取最新的再平衡记录
  Future<Rebalance?> findLatest() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'rebalances',
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return Rebalance.fromMap(maps.first);
    } catch (e) {
      _logger.e('Failed to find latest rebalance: $e');
      return null;
    }
  }
}
