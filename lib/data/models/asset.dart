/// 资产类型枚举
enum AssetType {
  stock('stock', '股票型'),
  bond('bond', '债券型');

  const AssetType(this.value, this.label);
  final String value;
  final String label;

  static AssetType fromString(String value) {
    return AssetType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AssetType.stock,
    );
  }
}

/// 资产模型
class Asset {
  final int? id;
  final String code;
  final String name;
  final String url;
  final AssetType type;
  final String source;
  final String encryptedAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Asset({
    this.id,
    required this.code,
    required this.name,
    required this.url,
    required this.type,
    required this.source,
    required this.encryptedAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库 Map 创建
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: AssetType.fromString(map['type'] as String),
      source: map['source'] as String,
      encryptedAmount: map['encrypted_amount'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'url': url,
      'type': type.value,
      'source': source,
      'encrypted_amount': encryptedAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  Asset copyWith({
    int? id,
    String? code,
    String? name,
    String? url,
    AssetType? type,
    String? source,
    String? encryptedAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      source: source ?? this.source,
      encryptedAmount: encryptedAmount ?? this.encryptedAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
