/// 基金信息模型
class FundInfo {
  final String code;
  final String name;
  final String? netValue;
  final String? updateTime;

  const FundInfo({
    required this.code,
    required this.name,
    this.netValue,
    this.updateTime,
  });

  /// 从 API JSON 创建
  factory FundInfo.fromJson(Map<String, dynamic> json) {
    return FundInfo(
      code: json['fundcode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      netValue: json['gsz'] as String?,
      updateTime: json['gztime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fundcode': code,
      'name': name,
      'gsz': netValue,
      'gztime': updateTime,
    };
  }
}
