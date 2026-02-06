import 'package:logger/logger.dart';
import '../models/asset.dart';
import '../models/fund_info.dart';
import '../repositories/asset_repository.dart';
import '../../core/utils/encryption_service.dart';
import '../../core/network/fund_api_service.dart';

/// 资产服务
class AssetService {
  final AssetRepository _assetRepo;
  final EncryptionService _encryption;
  final FundApiService _fundApi;
  final Logger _logger = Logger();

  AssetService(
    this._assetRepo,
    this._encryption,
    this._fundApi,
  );

  /// 获取所有资产
  Future<List<Asset>> getAllAssets() async {
    return await _assetRepo.findAll();
  }

  /// 根据 ID 获取资产
  Future<Asset?> getAssetById(int id) async {
    return await _assetRepo.findById(id);
  }

  /// 根据类型获取资产
  Future<List<Asset>> getAssetsByType(AssetType type) async {
    return await _assetRepo.findByType(type);
  }

  /// 创建资产
  Future<Asset> createAsset({
    required String code,
    required String source,
    required double amount,
  }) async {
    try {
      _logger.i('Creating asset with code: $code');

      // 查询基金信息
      final fundInfo = await _fundApi.fetchFundInfo(code);

      // 分类基金类型
      final typeStr = _fundApi.classifyFundType(fundInfo.name);
      final type = AssetType.fromString(typeStr);

      // 加密金额
      final encryptedAmount = _encryption.encryptAmount(amount);

      // 构建资产对象
      final now = DateTime.now();
      final asset = Asset(
        code: code,
        name: fundInfo.name,
        url: 'https://fund.eastmoney.com/$code.html',
        type: type,
        source: source,
        encryptedAmount: encryptedAmount,
        createdAt: now,
        updatedAt: now,
      );

      // 保存到数据库
      final created = await _assetRepo.create(asset);
      _logger.i('Asset created successfully: ${created.name}');

      return created;
    } catch (e) {
      _logger.e('Failed to create asset: $e');
      rethrow;
    }
  }

  /// 更新资产
  Future<void> updateAsset({
    required int id,
    AssetType? type,
    String? source,
    double? amount,
  }) async {
    try {
      final asset = await _assetRepo.findById(id);
      if (asset == null) {
        throw Exception('资产不存在');
      }

      // 构建更新后的资产
      final updatedAsset = asset.copyWith(
        type: type,
        source: source,
        encryptedAmount:
            amount != null ? _encryption.encryptAmount(amount) : null,
        updatedAt: DateTime.now(),
      );

      await _assetRepo.update(updatedAsset);
      _logger.i('Asset updated successfully: $id');
    } catch (e) {
      _logger.e('Failed to update asset: $e');
      rethrow;
    }
  }

  /// 删除资产
  Future<void> deleteAsset(int id) async {
    try {
      await _assetRepo.delete(id);
      _logger.i('Asset deleted successfully: $id');
    } catch (e) {
      _logger.e('Failed to delete asset: $e');
      rethrow;
    }
  }

  /// 查询基金信息
  Future<FundInfo> lookupFundInfo(String code) async {
    return await _fundApi.fetchFundInfo(code);
  }

  /// 获取投资组合总价值
  Future<double> getTotalValue() async {
    final assets = await _assetRepo.findAll();
    double total = 0;

    for (final asset in assets) {
      final amount = _encryption.decryptAmount(asset.encryptedAmount);
      total += amount;
    }

    return total;
  }

  /// 按类型统计资产
  Future<Map<AssetType, double>> getAssetsByTypeWithAmount() async {
    final assets = await _assetRepo.findAll();
    final result = <AssetType, double>{
      AssetType.stock: 0,
      AssetType.bond: 0,
    };

    for (final asset in assets) {
      final amount = _encryption.decryptAmount(asset.encryptedAmount);
      result[asset.type] = (result[asset.type] ?? 0) + amount;
    }

    return result;
  }

  /// 解密资产金额
  double decryptAmount(String encryptedAmount) {
    return _encryption.decryptAmount(encryptedAmount);
  }
}
