/// 应用常量
class AppConstants {
  // 应用信息
  static const String appName = 'Margin Mobile';
  static const String appVersion = '1.0.0';
  static const String appDescription = '安全边际投资组合管理工具';

  // 再平衡阈值（0.01% = 0.0001）
  static const double rebalanceThreshold = 0.0001;

  // 自动锁屏超时选项（分钟）
  static const List<int> autoLockTimeouts = [0, 1, 5, 10, 15, 30];

  // 天天基金 API
  static const String fundApiBaseUrl = 'https://fundgz.1234567.com.cn';

  // 基金类型关键词
  static const List<String> stockKeywords = [
    '股票',
    '指数',
    '混合',
    '沪深',
    '创业板',
    '科创板',
    '中证',
    '上证',
    '深证',
  ];

  static const List<String> bondKeywords = [
    '债券',
    '纯债',
    '信用债',
    '利率债',
    '可转债',
  ];

  // 默认来源
  static const List<String> defaultSources = [
    '支付宝',
    '微信',
    '天天基金',
    '蛋卷基金',
    '其他',
  ];
}
