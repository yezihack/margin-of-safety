import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../data/models/fund_info.dart';
import '../constants/app_constants.dart';

/// 基金 API 服务
class FundApiService {
  final Dio _dio;
  final Logger _logger = Logger();
  final Map<String, FundInfo> _cache = {};

  FundApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.fundApiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// 获取基金信息
  Future<FundInfo> fetchFundInfo(String code) async {
    try {
      _logger.i('Fetching fund info for code: $code');

      final response = await _dio.get(
        '/js/$code.js',
        queryParameters: {'rt': DateTime.now().millisecondsSinceEpoch},
      );

      if (response.statusCode == 200) {
        // 解析响应（格式: jsonpgz({"fundcode":"000001",...});）
        final data = response.data as String;
        final jsonStr = data.substring(
          data.indexOf('(') + 1,
          data.lastIndexOf(')'),
        );

        final json = jsonStr as Map<String, dynamic>;
        final fundInfo = FundInfo.fromJson(json);

        // 缓存结果
        _cache[code] = fundInfo;
        _logger.i('Fund info fetched successfully: ${fundInfo.name}');

        return fundInfo;
      } else {
        throw Exception('API 返回错误: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('Failed to fetch fund info: ${e.message}');

      // 尝试从缓存获取
      final cached = getCachedFundInfo(code);
      if (cached != null) {
        _logger.i('Using cached fund info');
        return cached;
      }

      throw Exception('获取基金信息失败，请检查网络连接');
    } catch (e) {
      _logger.e('Unexpected error: $e');
      throw Exception('获取基金信息失败: $e');
    }
  }

  /// 获取缓存的基金信息
  FundInfo? getCachedFundInfo(String code) {
    return _cache[code];
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _logger.i('Fund info cache cleared');
  }

  /// 根据基金名称分类基金类型
  String classifyFundType(String fundName) {
    // 检查是否包含股票型关键词
    for (final keyword in AppConstants.stockKeywords) {
      if (fundName.contains(keyword)) {
        return 'stock';
      }
    }

    // 检查是否包含债券型关键词
    for (final keyword in AppConstants.bondKeywords) {
      if (fundName.contains(keyword)) {
        return 'bond';
      }
    }

    // 默认为股票型
    return 'stock';
  }
}
