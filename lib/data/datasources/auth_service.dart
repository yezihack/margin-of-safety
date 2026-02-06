import 'dart:async';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import '../repositories/config_repository.dart';
import '../models/config.dart';
import '../../core/utils/encryption_service.dart';

/// 认证服务
class AuthService {
  final ConfigRepository _configRepo;
  final EncryptionService _encryption;
  final LocalAuthentication _localAuth;
  final Logger _logger = Logger();

  Timer? _autoLockTimer;
  bool _isAuthenticated = false;
  bool _isLocked = false;

  AuthService(
    this._configRepo,
    this._encryption, {
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  /// 是否已认证
  bool get isAuthenticated => _isAuthenticated;

  /// 是否已锁定
  bool get isLocked => _isLocked;

  /// 创建主密码
  Future<void> createMasterPassword(String password) async {
    try {
      _logger.i('Creating master password');

      // 哈希密码
      final hash = _encryption.hashPassword(password);

      // 保存到配置
      await _configRepo.setValue(ConfigKey.passwordHash, hash);

      // 初始化加密服务
      await _encryption.initialize(password);

      // 标记首次运行完成
      await _configRepo.setValue(ConfigKey.firstRun, 'false');

      _isAuthenticated = true;
      _logger.i('Master password created successfully');
    } catch (e) {
      _logger.e('Failed to create master password: $e');
      rethrow;
    }
  }

  /// 验证密码
  Future<bool> verifyPassword(String password) async {
    try {
      final storedHash = await _configRepo.getValue(ConfigKey.passwordHash);
      if (storedHash == null) {
        return false;
      }

      final hash = _encryption.hashPassword(password);
      return hash == storedHash;
    } catch (e) {
      _logger.e('Failed to verify password: $e');
      return false;
    }
  }

  /// 认证
  Future<bool> authenticate(String password) async {
    try {
      _logger.i('Authenticating user');

      final isValid = await verifyPassword(password);
      if (!isValid) {
        _logger.w('Invalid password');
        return false;
      }

      // 初始化加密服务
      await _encryption.initialize(password);

      _isAuthenticated = true;
      _isLocked = false;

      // 启动自动锁屏定时器
      await _startAutoLockTimer();

      _logger.i('Authentication successful');
      return true;
    } catch (e) {
      _logger.e('Authentication failed: $e');
      return false;
    }
  }

  /// 生物识别认证
  Future<bool> authenticateWithBiometric() async {
    try {
      _logger.i('Attempting biometric authentication');

      // 检查是否启用生物识别
      final enabled = await isBiometricEnabled();
      if (!enabled) {
        _logger.w('Biometric authentication not enabled');
        return false;
      }

      // 检查设备是否支持
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _logger.w('Device does not support biometrics');
        return false;
      }

      // 执行生物识别
      final authenticated = await _localAuth.authenticate(
        localizedReason: '请验证身份以访问应用',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isAuthenticated = true;
        _isLocked = false;
        await _startAutoLockTimer();
        _logger.i('Biometric authentication successful');
      }

      return authenticated;
    } catch (e) {
      _logger.e('Biometric authentication failed: $e');
      return false;
    }
  }

  /// 启用生物识别
  Future<void> enableBiometric() async {
    try {
      await _configRepo.setValue(ConfigKey.biometricEnabled, 'true');
      _logger.i('Biometric authentication enabled');
    } catch (e) {
      _logger.e('Failed to enable biometric: $e');
      rethrow;
    }
  }

  /// 禁用生物识别
  Future<void> disableBiometric() async {
    try {
      await _configRepo.setValue(ConfigKey.biometricEnabled, 'false');
      _logger.i('Biometric authentication disabled');
    } catch (e) {
      _logger.e('Failed to disable biometric: $e');
      rethrow;
    }
  }

  /// 检查是否启用生物识别
  Future<bool> isBiometricEnabled() async {
    final value = await _configRepo.getValue(ConfigKey.biometricEnabled);
    return value == 'true';
  }

  /// 更改主密码
  Future<void> changeMasterPassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      _logger.i('Changing master password');

      // 验证旧密码
      final isValid = await verifyPassword(oldPassword);
      if (!isValid) {
        throw Exception('旧密码错误');
      }

      // 哈希新密码
      final hash = _encryption.hashPassword(newPassword);

      // 保存新密码哈希
      await _configRepo.setValue(ConfigKey.passwordHash, hash);

      // 轮换加密密钥
      await _encryption.rotateKey(newPassword);

      _logger.i('Master password changed successfully');
    } catch (e) {
      _logger.e('Failed to change master password: $e');
      rethrow;
    }
  }

  /// 锁定应用
  void lock() {
    _isLocked = true;
    _isAuthenticated = false;
    _autoLockTimer?.cancel();
    _logger.i('Application locked');
  }

  /// 启动自动锁屏定时器
  Future<void> _startAutoLockTimer() async {
    _autoLockTimer?.cancel();

    final timeoutStr = await _configRepo.getValue(ConfigKey.autoLockTimeout);
    final timeout = int.tryParse(timeoutStr ?? '5') ?? 5;

    if (timeout > 0) {
      _autoLockTimer = Timer(Duration(minutes: timeout), () {
        lock();
        _logger.i('Auto-lock triggered after $timeout minutes');
      });
    }
  }

  /// 重置自动锁屏定时器
  Future<void> resetAutoLockTimer() async {
    if (_isAuthenticated && !_isLocked) {
      await _startAutoLockTimer();
    }
  }

  /// 检查是否首次运行
  Future<bool> isFirstRun() async {
    final value = await _configRepo.getValue(ConfigKey.firstRun);
    return value != 'false';
  }

  /// 清理资源
  void dispose() {
    _autoLockTimer?.cancel();
  }
}
