import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/rebalance.dart';
import '../../data/models/rebalance_calculation.dart';
import '../../data/datasources/rebalance_service.dart';
import '../../core/constants/strategies.dart';
import 'providers.dart';

/// 再平衡历史 Provider
final rebalanceHistoryProvider = FutureProvider<List<Rebalance>>((ref) async {
  final rebalanceService = ref.watch(rebalanceServiceProvider);
  return await rebalanceService.getHistory();
});

/// 最新再平衡记录 Provider
final latestRebalanceProvider = FutureProvider<Rebalance?>((ref) async {
  final rebalanceService = ref.watch(rebalanceServiceProvider);
  return await rebalanceService.getLatest();
});

/// 再平衡状态
class RebalanceState {
  final RebalanceCalculation? calculation;
  final StrategyType selectedStrategy;
  final double? customRatio;
  final bool isLoading;
  final String? error;

  const RebalanceState({
    this.calculation,
    this.selectedStrategy = StrategyType.balanced,
    this.customRatio,
    this.isLoading = false,
    this.error,
  });

  RebalanceState copyWith({
    RebalanceCalculation? calculation,
    StrategyType? selectedStrategy,
    double? customRatio,
    bool? isLoading,
    String? error,
  }) {
    return RebalanceState(
      calculation: calculation ?? this.calculation,
      selectedStrategy: selectedStrategy ?? this.selectedStrategy,
      customRatio: customRatio ?? this.customRatio,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 获取目标股票比例
  double get targetStockRatio {
    if (selectedStrategy == StrategyType.custom && customRatio != null) {
      return customRatio!;
    }
    final strategy = StrategyFactory.getStrategy(selectedStrategy);
    return strategy.stockRatio;
  }
}

/// 再平衡状态管理
class RebalanceNotifier extends StateNotifier<RebalanceState> {
  final RebalanceService _rebalanceService;
  final Ref _ref;

  RebalanceNotifier(this._rebalanceService, this._ref) : super(const RebalanceState());

  /// 选择策略
  void selectStrategy(StrategyType strategy, {double? customRatio}) {
    state = state.copyWith(
      selectedStrategy: strategy,
      customRatio: customRatio,
    );
    // 自动计算
    calculate();
  }

  /// 计算再平衡
  Future<void> calculate() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final calculation = await _rebalanceService.calculateRebalance(
        state.targetStockRatio,
      );
      state = state.copyWith(
        calculation: calculation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '计算失败: $e',
      );
    }
  }

  /// 执行再平衡
  Future<bool> execute(String? note) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _rebalanceService.executeRebalance(
        state.targetStockRatio,
        note,
      );
      
      // 刷新历史记录
      _ref.invalidate(rebalanceHistoryProvider);
      _ref.invalidate(latestRebalanceProvider);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '执行失败: $e',
      );
      return false;
    }
  }
}

/// 再平衡状态 Provider
final rebalanceProvider = StateNotifierProvider<RebalanceNotifier, RebalanceState>((ref) {
  final rebalanceService = ref.watch(rebalanceServiceProvider);
  return RebalanceNotifier(rebalanceService, ref);
});
