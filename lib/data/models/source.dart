/// 来源模型
class Source {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Source({
    this.id,
    required this.name,
    required this.createdAt,
  });

  /// 从数据库 Map 创建
  factory Source.fromMap(Map<String, dynamic> map) {
    return Source(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
