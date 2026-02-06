import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/database/database_service.dart';
import '../../core/utils/encryption_service.dart';
import '../../core/network/fund_api_service.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/config_repository.dart';
import '../../data/repositories/source_repository.dart';
import '../../data/repositories/rebalance_repository.dart';
import '../../data/datasources/asset_service.dart';
import '../../data/datasources/rebalance_service.dart';
import '../../data/datasources/auth_service.dart';

// ============================================================================
// 核心服务 Providers
// ============================================================================

/// 数据库服务
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// 加密服务
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// 基金 API 服务
final fundApiServiceProvider = Provider<FundApiService>((ref) {
  return FundApiService(dio: Dio());
});

/// 本地认证
final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

// ============================================================================
// Repository Providers
// ============================================================================

/// 资产仓库
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AssetRepository(dbService);
});

/// 配置仓库
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ConfigRepository(dbService);
});

/// 来源仓库
final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SourceRepository(dbService);
});

/// 再平衡仓库
final rebalanceRepositoryProvider = Provider<RebalanceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return RebalanceRepository(dbService);
});

// ============================================================================
// Service Providers
// ============================================================================

/// 资产服务
final assetServiceProvider = Provider<AssetService>((ref) {
  final assetRepo = ref.watch(assetRepositoryProvider);
  final encryption = ref.watch(encryptionServiceProvider);
  final fundApi = ref.watch(fundApiServiceProvider);
  return AssetService(assetRepo, encryption, fundApi);
});

/// 再平衡服务
final rebalanceServiceProvider = Provider<RebalanceService>((ref) {
  final rebalanceRepo = ref.watch(rebalanceRepositoryProvider);
  final assetService = ref.watch(assetServiceProvider);
  return RebalanceService(rebalanceRepo, assetService);
});

/// 认证服务
final authServiceProvider = Provider<AuthService>((ref) {
  final configRepo = ref.watch(configRepositoryProvider);
  final encryption = ref.watch(encryptionServiceProvider);
  final localAuth = ref.watch(localAuthProvider);
  return AuthService(configRepo, encryption, localAuth: localAuth);
});
