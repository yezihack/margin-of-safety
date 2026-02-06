/// 再平衡记录模型
class Rebalance {
  final int? id;
  final double stockRatio;
  final double bondRatio;
  final double totalAmount;
  final double stockAmount;
  final double bondAmount;
  final double targetStockRatio;
  final double targetBondRatio;
  final String? note;
  final DateTime createdAt;

  const Rebalance({
    this.id,
    required this.stockRatio,
    required this.bondRatio,
    required this.totalAmount,
    required this.stockAmount,
    required this.bondAmount,
    required this.targetStockRatio,
    required this.targetBondRatio,
    this.note,
    required this.createdAt,
  });

  /// 从数据库 Map 创建
  factory Rebalance.fromMap(Map<String, dynamic> map) {
    return Rebalance(
      id: map['id'] as int?,
      stockRatio: map['stock_ratio'] as double,
      bondRatio: map['bond_ratio'] as double,
      totalAmount: map['total_amount'] as double,
      stockAmount: map['stock_amount'] as double,
      bondAmount: map['bond_amount'] as double,
      targetStockRatio: map['target_stock_ratio'] as double,
      targetBondRatio: map['target_bond_ratio'] as double,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'stock_ratio': stockRatio,
      'bond_ratio': bondRatio,
      'total_amount': totalAmount,
      'stock_amount': stockAmount,
      'bond_amount': bondAmount,
      'target_stock_ratio': targetStockRatio,
      'target_bond_ratio': targetBondRatio,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
