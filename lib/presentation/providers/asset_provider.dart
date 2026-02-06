import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/asset.dart';
import '../../data/datasources/asset_service.dart';
import 'providers.dart';

/// 资产列表 Provider
final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final assetService = ref.watch(assetServiceProvider);
  return await assetService.getAllAssets();
});

/// 按类型分组的资产 Provider
final assetsByTypeProvider = FutureProvider<Map<AssetType, List<Asset>>>((ref) async {
  final assets = await ref.watch(assetListProvider.future);
  
  final grouped = <AssetType, List<Asset>>{
    AssetType.stock: [],
    AssetType.bond: [],
  };

  for (final asset in assets) {
    grouped[asset.type]?.add(asset);
  }

  return grouped;
});

/// 投资组合总价值 Provider
final portfolioTotalProvider = FutureProvider<double>((ref) async {
  final assetService = ref.watch(assetServiceProvider);
  return await assetService.getTotalValue();
});

/// 资产状态管理
class AssetNotifier extends StateNotifier<AsyncValue<List<Asset>>> {
  final AssetService _assetService;
  final Ref _ref;

  AssetNotifier(this._assetService, this._ref) : super(const AsyncValue.loading()) {
    loadAssets();
  }

  /// 加载资产列表
  Future<void> loadAssets() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _assetService.getAllAssets());
  }

  /// 创建资产
  Future<bool> createAsset({
    required String code,
    required String source,
    required double amount,
  }) async {
    try {
      await _assetService.createAsset(
        code: code,
        source: source,
        amount: amount,
      );
      await loadAssets();
      // 刷新相关 Provider
      _ref.invalidate(portfolioTotalProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// 更新资产
  Future<bool> updateAsset({
    required int id,
    AssetType? type,
    String? source,
    double? amount,
  }) async {
    try {
      await _assetService.updateAsset(
        id: id,
        type: type,
        source: source,
        amount: amount,
      );
      await loadAssets();
      _ref.invalidate(portfolioTotalProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// 删除资产
  Future<bool> deleteAsset(int id) async {
    try {
      await _assetService.deleteAsset(id);
      await loadAssets();
      _ref.invalidate(portfolioTotalProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// 解密金额
  double decryptAmount(String encryptedAmount) {
    return _assetService.decryptAmount(encryptedAmount);
  }
}

/// 资产状态 Provider
final assetNotifierProvider = StateNotifierProvider<AssetNotifier, AsyncValue<List<Asset>>>((ref) {
  final assetService = ref.watch(assetServiceProvider);
  return AssetNotifier(assetService, ref);
});
