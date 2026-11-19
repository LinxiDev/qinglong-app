<div align="center">

<img src="logo.png" width="120" height="120" alt="青龙客户端 Logo" />

<h1>青龙客户端</h1>

<p><strong>基于 <a href="https://github.com/whyour/qinglong">青龙面板</a> 打造的第三方跨平台客户端</strong></p>

<p>Android · iOS · Linux 桌面，一套代码，全平台覆盖</p>

<p>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.50.0-02569B?logo=flutter&logoColor=white" alt="Flutter 3.50.0"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.14-0175C2?logo=dart&logoColor=white" alt="Dart 3.14"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Linux-3DDC84?logo=android&logoColor=white" alt="Platform">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-blue" alt="License"></a>
  <a href="https://github.com/LinxiDev/qinglong-app/releases"><img src="https://img.shields.io/github/v/release/LinxiDev/qinglong-app?label=release&color=orange" alt="Release"></a>
</p>

<p>
  <a href="#功能特性">功能特性</a> ·
  <a href="#系统要求">系统要求</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#下载安装">下载安装</a> ·
  <a href="#集成测试">集成测试</a> ·
  <a href="#常见问题">常见问题</a> ·
  <a href="https://github.com/LinxiDev/qinglong-app/wiki">Wiki</a>
</p>

</div>

---

## 项目简介

青龙客户端（`qinglong-app`）是基于 [青龙面板](https://github.com/whyour/qinglong) 的第三方客户端，使用 **Flutter** 构建，一套代码同时覆盖 **Android / iOS / Linux 桌面**。

- 作者：**林夕**
- 功能对齐青龙面板 **v2.22 ~ v2.25**
- 支持多账号、多面板切换，深色模式全量适配

## 功能特性

| 模块 | 说明 |
| :--- | :--- |
| 🔐 多账号 / 多面板 | 同时管理多个青龙面板，一键切换身份，长按删除、拖拽排序 |
| ⏰ 定时任务 | 任务列表（置顶 / 状态 / 筛选）、任务详情、日志查看、批量启停与运行 |
| 🔑 环境变量 | 变量增删改查、置顶排序、启用禁用、批量操作 |
| 📄 配置文件 | 查看与编辑，桌面端提供只读降级视图，支持新增配置 |
| 📜 脚本管理 | 树形文件浏览、脚本编辑、历史版本对比与恢复 |
| 📦 订阅与依赖 | 订阅管理，依赖安装 / 卸载 / 重装 |
| 🧾 日志中心 | 任务日志、登录日志、通知日志一站式查看 |
| 📊 运行概览 | Dashboard 面板状态与运行数据一目了然 |
| 🔔 通知设置 | 支持 Bark / Telegram / 钉钉 / 飞书 / 企业微信 / PushPlus 等主流渠道 |
| ☁️ iCloud 备份 | iOS 端配置与环境变量云备份 |
| 🌙 深色模式 | 全量适配，跟随系统或手动切换 |
| 🆕 版本检测 | 基于 GitHub Releases 的 APP 更新提示 |

## 系统要求

| 平台 | 最低要求 | 说明 |
| :--- | :--- | :--- |
| Android | 7.0（API 24）及以上 | 覆盖主流机型 |
| iOS | 15.0 及以上 | 需自签或通过 TestFlight 安装 |
| Linux 桌面 | GTK 3.24+ | 用于开发与集成测试 |
| Flutter | 3.50.0 | Dart SDK ^3.14.0 |
| 青龙面板 | 建议 v2.20+ | 部分功能要求 v2.22 / v2.23+，App 内会给出提示 |

## 快速开始

> 请先安装 [Flutter 3.50.0](https://docs.flutter.dev/get-started/install)（含 Dart 3.14），并配置对应平台的开发环境。

```bash
# 1. 克隆仓库
git clone https://github.com/LinxiDev/qinglong-app.git
cd qinglong-app

# 2. 安装依赖
flutter pub get

# 3. 运行（Android / iOS / Linux 桌面）
flutter run
```

打包发布：

| 平台 | 命令 | 产物 |
| :--- | :--- | :--- |
| Android | `flutter build apk --release` | `qinglong_app-x.y.z.apk` |
| iOS | `flutter build ipa --release` | `qinglong_app-x.y.z.ipa`（需签名配置） |
| Linux 桌面 | `flutter build linux --debug` | 桌面可执行文件 |

## 下载安装

前往 [Releases](https://github.com/LinxiDev/qinglong-app/releases) 下载对应平台的安装包：

| 文件 | 平台 | 安装方式 |
| :--- | :--- | :--- |
| `qinglong_app-x.y.z.apk` | Android | 直接安装 |
| `qinglong_app-x.y.z.ipa` | iOS | 自签（TrollStore / AltStore / Xcode）或 TestFlight |

## 集成测试

项目内置 **7 个**真实面板集成测试（页面遍历、空状态、增删改流程），默认使用青龙官方演示面板，无需任何配置即可运行：

```bash
flutter test integration_test/smoke_test.dart -d linux
```

如需指向自己的面板，先导出以下环境变量：

```bash
export QL_HOST=http://your-panel:5700
export QL_USER=admin
export QL_PASS=your-password
```

> 测试结束后会自动清理以 `TEST_UI_VAR_*` / `UI_TEST_TASK_*` 命名的测试数据。

## CI/CD

| 工作流 | 触发条件 | 产物 |
| :--- | :--- | :--- |
| `android-ci` | push / PR | APK 构建校验 + analyze / test |
| `android-release` | 推送 `v*` 标签 | `qinglong_app-x.y.z.apk` → GitHub Release |
| `ios-ci` | push / PR | 未签名 IPA 构建校验 |
| `ios-release` | 推送 `v*` 标签 / 手动 | `qinglong_app-x.y.z.ipa` → GitHub Release + dSYM |
| `integration-test` | push / PR / 手动 | Linux 桌面真面板集成测试 |

完整文档见 [GitHub Wiki](https://github.com/LinxiDev/qinglong-app/wiki)，本地副本位于 [`wiki/`](wiki/) 目录。

## 项目结构

```text
qinglong-app/
├── lib/
│   ├── base/                 # 基础设施：HTTP、主题、路由、多账号、通用组件
│   ├── module/               # 业务页面（task/env/config/scripts/subscribe/...）
│   └── utils/                # 工具类（IDN、SP、日志等）
├── test/                     # 单元测试
├── integration_test/         # 真实面板集成测试
├── docs/                     # 开发文档与截图
├── wiki/                     # Wiki 文档源文件
└── .github/workflows/        # CI/CD 流水线
```

## 常见问题

- **中文域名登录失败？** v4.1.0 起已支持，App 会自动把中文域名转换为 Punycode（`xn--`）格式；旧版本请手动填写解析后的域名。
- **键盘无法弹出（Android）？** 长按文本框即可唤起软键盘，详见 App 内提示。
- **多账号有上限吗？** 普通用户 5 个，VIP 不限。
- 更多问题见 [Wiki 常见问题](https://github.com/LinxiDev/qinglong-app/wiki)。

## 相关链接

| 资源 | 地址 |
| :--- | :--- |
| 青龙面板 | [whyour/qinglong](https://github.com/whyour/qinglong) |
| 版本下载 | [GitHub Releases](https://github.com/LinxiDev/qinglong-app/releases) |
| 使用文档 | [GitHub Wiki](https://github.com/LinxiDev/qinglong-app/wiki) |
| 问题反馈 | [GitHub Issues](https://github.com/LinxiDev/qinglong-app/issues) |
| 更新日志 | [CHANGELOG.md](CHANGELOG.md) |

## 免责声明

本项目为青龙面板的第三方客户端，与青龙官方无关。请合理使用脚本功能，遵守目标站点的服务条款。

## 许可证

本项目基于 [GNU AGPL-3.0](LICENSE) 协议开源。

<div align="center">

<sub>如果这个项目对你有帮助，欢迎点一个 ⭐ Star 支持一下</sub>

</div>
