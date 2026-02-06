import 'package:logger/logger.dart';
import '../models/rebalance.dart';
import '../models/rebalance_calculation.dart';
import '../repositories/rebalance_repository.dart';
import 'asset_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/strategies.dart';

/// 再平衡服务
class RebalanceService {
  final RebalanceRepository _rebalanceRepo;
  final AssetService _assetService;
  final Logger _logger = Logger();

  RebalanceService(
    this._rebalanceRepo,
    this._assetService,
  );

  /// 计算再平衡
  Future<RebalanceCalculation> calculateRebalance(
    double targetStockRatio,
  ) async {
    try {
      _logger.i('Calculating rebalance with target ratio: $targetStockRatio');

      // 获取当前资产分布
      final assetsByType = await _assetService.getAssetsByTypeWithAmount();
      final totalAmount = await _assetService.getTotalValue();

      if (totalAmount == 0) {
        throw Exception('投资组合为空，无法计算再平衡');
      }

      final currentStockAmount = assetsByType[AssetType.stock] ?? 0;
      final currentBondAmount = assetsByType[AssetType.bond] ?? 0;

      // 计算当前比例
      final currentStockRatio = currentStockAmount / totalAmount;
      final currentBondRatio = currentBondAmount / totalAmount;

      // 计算目标金额
      final targetBondRatio = 1 - targetStockRatio;
      final targetStockAmount = totalAmount * targetStockRatio;
      final targetBondAmount = totalAmount * targetBondRatio;

      // 判断是否需要再平衡
      final needsRebalance = await this.needsRebalance(
        targetStockRatio,
        AppConstants.rebalanceThreshold,
      );

      // 生成调整建议
      final suggestions = _generateSuggestions(
        currentStockAmount,
        currentBondAmount,
        targetStockAmount,
        targetBondAmount,
      );

      return RebalanceCalculation(
        currentStockRatio: currentStockRatio,
        currentBondRatio: currentBondRatio,
        targetStockRatio: targetStockRatio,
        targetBondRatio: targetBondRatio,
        totalAmount: totalAmount,
        currentStockAmount: currentStockAmount,
        currentBondAmount: currentBondAmount,
        targetStockAmount: targetStockAmount,
        targetBondAmount: targetBondAmount,
        needsRebalance: needsRebalance,
        suggestions: suggestions,
      );
    } catch (e) {
      _logger.e('Failed to calculate rebalance: $e');
      rethrow;
    }
  }

  /// 判断是否需要再平衡
  Future<bool> needsRebalance(
    double targetStockRatio,
    double threshold,
  ) async {
    final assetsByType = await _assetService.getAssetsByTypeWithAmount();
    final totalAmount = await _assetService.getTotalValue();

    if (totalAmount == 0) return false;

    final currentStockAmount = assetsByType[AssetType.stock] ?? 0;
    final currentStockRatio = currentStockAmount / totalAmount;

    final deviation = (currentStockRatio - targetStockRatio).abs();
    return deviation > threshold;
  }

  /// 执行再平衡
  Future<Rebalance> executeRebalance(
    double targetStockRatio,
    String? note,
  ) async {
    try {
      _logger.i('Executing rebalance');

      // 计算再平衡
      final calculation = await calculateRebalance(targetStockRatio);

      // 创建再平衡记录
      final rebalance = Rebalance(
        stockRatio: calculation.currentStockRatio,
        bondRatio: calculation.currentBondRatio,
        totalAmount: calculation.totalAmount,
        stockAmount: calculation.currentStockAmount,
        bondAmount: calculation.currentBondAmount,
        targetStockRatio: calculation.targetStockRatio,
        targetBondRatio: calculation.targetBondRatio,
        note: note,
        createdAt: DateTime.now(),
      );

      final created = await _rebalanceRepo.create(rebalance);
      _logger.i('Rebalance executed successfully');

      return created;
    } catch (e) {
      _logger.e('Failed to execute rebalance: $e');
      rethrow;
    }
  }

  /// 获取历史记录
  Future<List<Rebalance>> getHistory() async {
    return await _rebalanceRepo.findAll();
  }

  /// 获取最新记录
  Future<Rebalance?> getLatest() async {
    return await _rebalanceRepo.findLatest();
  }

  /// 获取策略
  Strategy getStrategy(StrategyType type, {double? customRatio}) {
    return StrategyFactory.getStrategy(type, customRatio: customRatio);
  }

  /// 生成调整建议
  Map<String, double> _generateSuggestions(
    double currentStock,
    double currentBond,
    double targetStock,
    double targetBond,
  ) {
    final stockAdjustment = targetStock - currentStock;
    final bondAdjustment = targetBond - currentBond;

    return {
      'stock': stockAdjustment,
      'bond': bondAdjustment,
    };
  }
}
