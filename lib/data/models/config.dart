/// 配置键枚举
enum ConfigKey {
  passwordHash('password_hash'),
  encryptKey('encrypt_key'),
  firstRun('first_run'),
  autoLockTimeout('auto_lock_timeout'),
  biometricEnabled('biometric_enabled'),
  darkMode('dark_mode');

  const ConfigKey(this.value);
  final String value;

  static ConfigKey fromString(String value) {
    return ConfigKey.values.firstWhere(
      (key) => key.value == value,
      orElse: () => ConfigKey.firstRun,
    );
  }
}

/// 配置模型
class Config {
  final int? id;
  final ConfigKey key;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Config({
    this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库 Map 创建
  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      id: map['id'] as int?,
      key: ConfigKey.fromString(map['key'] as String),
      value: map['value'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'key': key.value,
      'value': value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
