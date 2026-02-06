/// 投资策略接口
abstract class Strategy {
  double get stockRatio;
  double get bondRatio;
  String get name;
  String get description;
}

/// 防御型策略（25% 股票 / 75% 债券）
class DefensiveStrategy implements Strategy {
  @override
  double get stockRatio => 0.25;

  @override
  double get bondRatio => 0.75;

  @override
  String get name => '防御型';

  @override
  String get description => '适合新手、心理敏感型投资者';
}

/// 平衡型策略（50% 股票 / 50% 债券）
class BalancedStrategy implements Strategy {
  @override
  double get stockRatio => 0.50;

  @override
  double get bondRatio => 0.50;

  @override
  String get name => '平衡型';

  @override
  String get description => '格雷厄姆推荐的经典配置';
}

/// 进取型策略（70% 股票 / 30% 债券）
class AggressiveStrategy implements Strategy {
  @override
  double get stockRatio => 0.70;

  @override
  double get bondRatio => 0.30;

  @override
  String get name => '进取型';

  @override
  String get description => '适合有认知、有纪律的投资者';
}

/// 自定义策略
class CustomStrategy implements Strategy {
  final double _stockRatio;

  CustomStrategy(this._stockRatio)
      : assert(_stockRatio >= 0 && _stockRatio <= 1, '股票比例必须在 0-1 之间');

  @override
  double get stockRatio => _stockRatio;

  @override
  double get bondRatio => 1 - _stockRatio;

  @override
  String get name => '自定义';

  @override
  String get description => '自定义股债比例';
}

/// 策略类型枚举
enum StrategyType {
  defensive,
  balanced,
  aggressive,
  custom,
}

/// 策略工厂
class StrategyFactory {
  static Strategy getStrategy(StrategyType type, {double? customRatio}) {
    switch (type) {
      case StrategyType.defensive:
        return DefensiveStrategy();
      case StrategyType.balanced:
        return BalancedStrategy();
      case StrategyType.aggressive:
        return AggressiveStrategy();
      case StrategyType.custom:
        if (customRatio == null) {
          throw ArgumentError('自定义策略需要提供股票比例');
        }
        return CustomStrategy(customRatio);
    }
  }

  static List<Strategy> getAllPredefinedStrategies() {
    return [
      DefensiveStrategy(),
      BalancedStrategy(),
      AggressiveStrategy(),
    ];
  }
}
