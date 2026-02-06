# Margin Mobile - 安全边际投资组合管理工具（移动端）

> Build portfolios that survive uncertainty - Now on your mobile device

基于格雷厄姆"安全边际"理念的投资组合管理工具移动版，使用 Flutter 构建，支持 iOS 和 Android 平台。

## ✨ 核心功能

- 📊 **资产管理** - 自动识别基金类型，支持多来源管理
- ⚖️ **再平衡建议** - 智能计算资产配置偏差，提供调整方案
- 📈 **历史追踪** - 记录每次再平衡操作，可视化趋势分析
- 🔒 **数据加密** - AES-256-GCM 加密保护资产金额
- 🔐 **生物识别** - 支持指纹/面容识别快速登录
- 📴 **离线优先** - 所有核心功能完全离线可用

## 🚀 快速开始

### 环境要求

- Flutter 3.x+
- Dart 3.10+
- Android Studio / Xcode（用于构建对应平台）

### 安装依赖

```bash
flutter pub get
```

### 开发模式

```bash
# Android
flutter run

# iOS
flutter run -d ios

# 指定设备
flutter devices
flutter run -d <device-id>
```

### 构建应用

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

## 📖 使用指南

### 首次使用

1. **设置密码** - 首次启动时设置主密码（用于数据加密）
2. **启用生物识别**（可选）- 在设置中开启指纹/面容识别
3. **添加资产** - 输入基金代码，系统自动识别类型
4. **选择策略** - 选择防御型(25%)、平衡型(50%)或进取型(70%)
5. **查看建议** - 系统计算并显示再平衡建议

### 三种投资策略

| 策略 | 股票比例 | 债券比例 | 适合人群 |
|------|---------|---------|---------|
| 🛡 极度防御型 | 25% | 75% | 新手、心理敏感型 |
| ⚖️ 平衡型 | 50% | 50% | 格雷厄姆推荐 |
| ⚔️ 进取型 | 70% | 30% | 有认知、有纪律 |

### 再平衡触发条件

当实际比例与目标比例偏差超过 **0.01%** 时，系统会提示需要再平衡。

## 🛠️ 技术栈

- **框架**: Flutter 3.x / Dart 3.10+
- **状态管理**: Riverpod 2.5+
- **本地数据库**: sqflite 2.3+
- **加密**: encrypt 5.0+ (AES-256-GCM)
- **安全存储**: flutter_secure_storage 9.0+
- **生物识别**: local_auth 2.2+
- **图表**: fl_chart 0.66+
- **网络**: dio 5.4+

## 📁 项目结构

```
lib/
├── core/                      # 核心模块
│   ├── constants/             # 常量定义
│   ├── network/               # 网络层
│   ├── database/              # 数据库服务
│   └── utils/                 # 工具类
│
├── data/                      # 数据层
│   ├── models/                # 数据模型
│   ├── repositories/          # 仓库层
│   └── datasources/           # 数据源
│
├── presentation/              # 表现层
│   ├── screens/               # 页面
│   ├── widgets/               # 组件
│   └── providers/             # 状态管理
│
└── routes/                    # 路由配置
```

## 📱 数据存储

数据库文件存储在应用沙盒目录：

- **Android**: `/data/data/com.marginofsafety.margin_mobile/databases/margin.db`
- **iOS**: `Library/Application Support/margin.db`

## 🔐 安全特性

- ✅ 金额数据 AES-256-GCM 加密
- ✅ 密码本地存储（SHA-256 哈希）
- ✅ 支持生物识别（指纹/面容）
- ✅ 可配置自动锁屏（0-30分钟）
- ✅ 加密密钥安全存储（Keychain/Keystore）

## 🌐 桌面版本

桌面版（Wails）代码已保存在 `history` 分支，可通过以下命令查看：

```bash
git checkout history
```

## 📚 详细文档

- [设计文档](.kiro/specs/mobile-app/design.md)
- [入门手册](./USER_GUIDE.md)

## 📄 许可证

本项目采用 GNU 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

本项目灵感来源于本杰明·格雷厄姆的《聪明的投资者》中的"安全边际"理念。

---

**注意**: 本工具仅用于资产配置管理，不提供投资建议。投资有风险，决策需谨慎。
