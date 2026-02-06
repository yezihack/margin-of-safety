/// 再平衡计算结果
class RebalanceCalculation {
  final double currentStockRatio;
  final double currentBondRatio;
  final double targetStockRatio;
  final double targetBondRatio;
  final double totalAmount;
  final double currentStockAmount;
  final double currentBondAmount;
  final double targetStockAmount;
  final double targetBondAmount;
  final bool needsRebalance;
  final Map<String, double> suggestions;

  const RebalanceCalculation({
    required this.currentStockRatio,
    required this.currentBondRatio,
    required this.targetStockRatio,
    required this.targetBondRatio,
    required this.totalAmount,
    required this.currentStockAmount,
    required this.currentBondAmount,
    required this.targetStockAmount,
    required this.targetBondAmount,
    required this.needsRebalance,
    required this.suggestions,
  });

  /// 股票调整金额（正数表示买入，负数表示卖出）
  double get stockAdjustment => targetStockAmount - currentStockAmount;

  /// 债券调整金额（正数表示买入，负数表示卖出）
  double get bondAdjustment => targetBondAmount - currentBondAmount;

  /// 偏差百分比
  double get deviationPercentage =>
      (currentStockRatio - targetStockRatio).abs() * 100;
}
