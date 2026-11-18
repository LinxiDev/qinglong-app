# 青龙客户端 (qinglong-app)

基于 [青龙面板](https://github.com/whyour/qinglong) 打造的第三方跨平台客户端，支持 **Android / iOS / Linux 桌面**。

> 作者：**林夕** · 下载：[GitHub Releases](https://github.com/LinxiDev/qinglong-app/releases) · 文档：[GitHub Wiki](https://github.com/LinxiDev/qinglong-app/wiki)

## 功能特性

- 🔐 **多账号与多面板**：支持同时管理多个青龙面板，一键切换身份、长按删除、拖拽排序
- ⏰ **定时任务**：任务列表（置顶/状态/筛选）、任务详情、日志查看、批量启停与运行
- 🔑 **环境变量**：变量增删改查、置顶排序、启用禁用、批量操作
- 📄 **配置文件**：查看与编辑（桌面端提供只读降级视图）、新增配置
- 📜 **脚本管理**：树形文件浏览、脚本编辑、历史版本对比与恢复
- 📦 **订阅与依赖**：订阅管理、依赖安装/卸载/重装
- 🧾 **任务日志 / 登录日志 / 通知日志**：运行记录一站式查看
- 📊 **运行概览（Dashboard）**：面板状态一目了然
- 🔔 **通知设置**：支持 Bark / Telegram / 钉钉 / 飞书 / 企业微信 / PushPlus 等主流渠道
- ☁️ **iCloud 文件备份**（iOS）：配置与环境变量云备份
- 🌙 **深色模式**：全量适配，跟随系统或手动切换
- 🆕 **版本检测**：基于 GitHub Releases 的 APP 更新提示

## 系统要求

| 平台 | 要求 |
| --- | --- |
| Android | 7.0（API 24）及以上 |
| iOS | 15.0 及以上 |
| Linux 桌面 | GTK 3.24+（用于开发与集成测试） |
| Flutter | 3.50.0（Dart SDK ^3.14.0） |
| 青龙面板 | 建议 v2.20+（部分功能要求 v2.22/v2.23+，App 内有版本提示） |

## 快速开始

```bash
# 1. 克隆
git clone https://github.com/LinxiDev/qinglong-app.git
cd qinglong-app

# 2. 安装依赖
flutter pub get

# 3. 运行（Android / iOS / Linux 桌面）
flutter run
```

打包发布：

```bash
flutter build apk --release      # Android APK
flutter build ipa --release      # iOS IPA（需签名配置）
flutter build linux --debug      # Linux 桌面
```

## 下载安装

前往 [Releases](https://github.com/LinxiDev/qinglong-app/releases) 下载对应平台的安装包：

- `qinglong_app-x.y.z.apk` —— Android 直接安装
- `qinglong_app-x.y.z.ipa` —— iOS 需自签（TrollStore / AltStore / Xcode）或 TestFlight

## 集成测试

项目内置 7 个真实面板集成测试（页面遍历、空态、增删改流程），默认使用青龙官方演示面板，无需任何配置：

```bash
flutter test integration_test/smoke_test.dart -d linux
```

指向自己的面板：

```bash
export QL_HOST=http://your-panel:5700
export QL_USER=admin
export QL_PASS=your-password
```

测试结束后会自动清理以 `TEST_UI_VAR_*` / `UI_TEST_TASK_*` 命名的测试数据。

## CI/CD

| 工作流 | 触发 | 产物 |
| --- | --- | --- |
| `android-ci` | push / PR | APK 构建校验 + analyze/test |
| `android-release` | 推送 `v*` 标签 | `qinglong_app-x.y.z.apk` → GitHub Release |
| `ios-ci` | push / PR | 未签名 IPA 构建校验 |
| `ios-release` | 推送 `v*` 标签 / 手动 | `qinglong_app-x.y.z.ipa` → GitHub Release + dSYM |
| `integration-test` | push / PR / 手动 | Linux 桌面真面板集成测试 |

完整文档见 [GitHub Wiki](https://github.com/LinxiDev/qinglong-app/wiki)（本地副本在 [`wiki/`](wiki/) 目录）。

## 项目结构

```
lib/
├── base/           # 基础设施：HTTP、主题、路由、多账号、通用组件
├── module/         # 业务页面（task/env/config/scripts/subscribe/...）
└── utils/          # 工具类（IDN、SP、日志等）
test/               # 单元测试
integration_test/   # 真实面板集成测试
.github/workflows/  # CI/CD 流水线
wiki/               # 文档源文件
```

## 常见问题

- **中文域名登录失败？** v4.1.0 起已支持，App 会自动把中文域名转换为 Punycode（xn--）格式；旧版本请手动填写解析后的域名。
- **键盘无法弹出（Android）？** 长按文本框即可唤起软键盘（详见 App 内提示）。
- **多账号有上限吗？** 普通用户 5 个，VIP 不限。
- 更多问题见 [Wiki 常见问题](https://github.com/LinxiDev/qinglong-app/wiki)。

## 免责声明

本项目为青龙面板的第三方客户端，与青龙官方无关。请合理使用脚本功能，遵守目标站点的服务条款。

## 许可证

[LICENSE](LICENSE)
