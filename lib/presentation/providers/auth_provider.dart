import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_service.dart';
import 'providers.dart';

/// 认证状态
class AuthState {
  final bool isAuthenticated;
  final bool isLocked;
  final bool isFirstRun;
  final bool biometricEnabled;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLocked = false,
    this.isFirstRun = true,
    this.biometricEnabled = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLocked,
    bool? isFirstRun,
    bool? biometricEnabled,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLocked: isLocked ?? this.isLocked,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 认证状态管理
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    final isFirstRun = await _authService.isFirstRun();
    final biometricEnabled = await _authService.isBiometricEnabled();

    state = state.copyWith(
      isFirstRun: isFirstRun,
      biometricEnabled: biometricEnabled,
    );
  }

  /// 创建主密码
  Future<bool> createMasterPassword(String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.createMasterPassword(password);
      state = state.copyWith(
        isAuthenticated: true,
        isFirstRun: false,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '创建密码失败: $e',
      );
      return false;
    }
  }

  /// 密码认证
  Future<bool> authenticate(String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.authenticate(password);
      if (success) {
        state = state.copyWith(
          isAuthenticated: true,
          isLocked: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '密码错误',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '认证失败: $e',
      );
      return false;
    }
  }

  /// 生物识别认证
  Future<bool> authenticateWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.authenticateWithBiometric();
      if (success) {
        state = state.copyWith(
          isAuthenticated: true,
          isLocked: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '生物识别失败',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '生物识别失败: $e',
      );
      return false;
    }
  }

  /// 启用生物识别
  Future<void> enableBiometric() async {
    try {
      await _authService.enableBiometric();
      state = state.copyWith(biometricEnabled: true);
    } catch (e) {
      state = state.copyWith(error: '启用生物识别失败: $e');
    }
  }

  /// 禁用生物识别
  Future<void> disableBiometric() async {
    try {
      await _authService.disableBiometric();
      state = state.copyWith(biometricEnabled: false);
    } catch (e) {
      state = state.copyWith(error: '禁用生物识别失败: $e');
    }
  }

  /// 锁定应用
  void lock() {
    _authService.lock();
    state = state.copyWith(
      isLocked: true,
      isAuthenticated: false,
    );
  }

  /// 重置自动锁屏定时器
  Future<void> resetAutoLockTimer() async {
    await _authService.resetAutoLockTimer();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}

/// 认证状态 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
