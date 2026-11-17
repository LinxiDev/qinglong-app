# qinglong-app — 青龙面板客户端

> 基于 **Flutter** 开发的青龙面板第三方移动客户端，支持 Android / iOS 双端，可在手机上完整管理青龙面板的任务、订阅、环境变量、脚本、依赖、配置、日志等核心功能。

| 项目性质 | 上游依赖 | 维护者 |
|:---:|:---:|:---:|
| 客户端 App（非服务端） | [whyour/qinglong](https://github.com/whyour/qinglong) | yanyu |

---

## 技术栈

| 分类 | 选型 |
|---|---|
| 框架 | Flutter 3.50 / Dart 3.14 |
| UI | `material_ui` + `cupertino_ui`（Flutter 3.47+ 官方新包） |
| 状态管理 | Riverpod 3 |
| 网络 | Dio 5 + 自定义 Token 拦截器 |
| 本地存储 | SharedPreferences |
| 代码编辑器 | CodeMirror（WebView 4） |
| 依赖注入 | get_it 9 |
| 构建 | Gradle 9.5 / AGP 9.3 / Kotlin 2.4（Kotlin DSL）、Java 17 |

> 接口文档参考：[青龙 OpenAPI](https://qinglong.online/api/index)。面板侧能力以 v2.24 ~ v2.25 为基准，
> 旧版本面板会自动降级提示。

---

## 功能特性

### 账号与登录

- **多账号管理**：支持同时添加多个青龙面板账号，账号间数据与会话完全隔离，一键切换
- **账号密码登录**：对接常规 `/api/*` 接口，支持两步验证
- **OpenAPI 登录**：使用 `client_id / client_secret` 对接 `/open/*` 接口（部分功能需在面板侧分配对应 scope 权限）
- **扫码登录 / 生物识别解锁**

### 核心管理功能

| 模块 | 功能说明 |
|---|---|
| **定时任务** | 查看、搜索、启停、置顶、手动运行、编辑；定时规则预览、运行实例与强制停止 |
| **订阅管理** | 订阅列表、运行/停止、启用/禁用、日志查看 |
| **环境变量** | 增删改查、批量操作、启用/禁用、搜索、排序移动、置顶、重命名 |
| **配置文件** | 文件列表、内容查看、在线编辑与保存、JSON 表格视图 |
| **脚本管理** | 目录浏览、查看、在线编辑、上传/新增/删除、运行/停止、**历史版本对比与还原** |
| **依赖管理** | 依赖列表、安装/卸载/重装、刷新与取消、查看安装日志 |
| **日志中心** | 任务运行日志、登录日志、系统日志、**通知审计日志** |
| **运行概览** | 今日运行数/成功率/平均耗时、近 7 日趋势、耗时与次数排行 |
| **数据清理** | 运行实例与统计数据保留策略、依赖缓存清理、数据库压缩，支持预览后再执行 |
| **安全设置** | 修改密码、IP 黑名单、应用（AppKey）管理 |
| **系统信息** | 面板版本、系统状态、更新检测 |

### 其他

- 主题切换（亮色 / 暗色 / 纯白），Logo 与启动图自动适配暗色
- 文字缩放与基础显示设置
- 内置代码编辑器（CodeMirror）
- iCloud 数据同步支持（iOS）
- 应用内购与赞助页面

---

## 接口说明

本项目对接青龙面板两套接口体系：

```
常规登录  →  /api/*
OpenAPI   →  /open/*
```

> 面板侧通过 `rewrite('/open/*', '/api/$1')` 将 `/open` 映射到同一套路由，因此两套前缀能力一致，
> 差别仅在鉴权方式与 scope 校验。使用 OpenAPI 登录时若返回 `401`，通常是面板未为该应用分配对应权限，
> 请在「应用管理」中检查授权。

新增能力对应的接口：

| 功能 | 接口 |
|---|---|
| 脚本运行/停止/重命名 | `PUT /scripts/run`、`PUT /scripts/stop`、`PUT /scripts/rename` |
| 脚本历史版本 | `GET /scripts/history`、`GET /scripts/history/detail`、`PUT /scripts/history/restore` |
| 定时规则预览 | `GET /crons/preview` |
| 任务运行实例 | `GET /crons/:id/instances`、`POST /crons/:id/instances/:instanceId/stop` |
| 运行概览 | `GET /dashboard/overview`、`/trend`、`/top-time`、`/top-count` |
| 通知审计日志 | `GET /system/notify-log` |
| 数据清理 | `PUT /system/storage-retention/config`、`POST /preview`、`POST /cleanup` |
| IP 黑名单 | `GET/PUT/DELETE /user/ip-blacklist` |
| 环境变量置顶 | `PUT /envs/pin`、`PUT /envs/unpin`、`PUT /envs/name` |

---

## 代码结构

```
lib/
├── main.dart                  # 应用入口，多账号容器与全局初始化
├── base/                      # 基础设施层
│   ├── http/                  # HTTP 封装、Token 拦截器、接口与路由定义
│   ├── theme.dart             # 主题配置
│   ├── routes.dart            # 路由管理
│   └── ui/                    # 通用 UI 组件（含 JSON 表格、抖动动画、Logo 等）
├── utils/
│   ├── diff_util.dart         # 行级文本差异（脚本历史对比）
│   └── ...                    # 存储、iCloud、格式化等
└── module/                    # 业务模块
    ├── home/                  # 首页 & 系统信息
    ├── task/                  # 定时任务、运行实例、任务日志
    ├── subscribe/             # 订阅管理
    ├── env/                   # 环境变量
    ├── config/                # 配置文件
    ├── dashboard/             # 运行概览
    ├── setting/               # 数据清理、IP 黑名单
    ├── others/                # 脚本、依赖、日志、通知日志、关于等
    ├── appkey/                # 应用管理（Apps / AppKeys）
    ├── login/                 # 登录页面
    ├── code_editor/           # 内置代码编辑器
    └── ...                    # 设置、订阅、推送、扫描等页面
```

---

## 快速开始

### 环境要求

- Flutter SDK **3.50.0 及以上**（Dart 3.14）
- Android：Android SDK 36、JDK 17
- iOS：Xcode 15+，最低部署版本 15.0

### 运行

```bash
# 获取依赖
flutter pub get

# 代码检查与测试
flutter analyze
flutter test

# 连接设备后运行
flutter run
```

### 构建发布包

```bash
# Android APK
flutter build apk --release

# iOS（需 macOS + Xcode）
flutter build ios --release
```

### 图标与启动图

```bash
# 重新生成应用图标（基于 assets/images/ic_launcher.png）
dart run flutter_launcher_icons

# 重新生成原生启动图（含暗色）
dart run flutter_native_splash:create
```

---

## 致谢

- 青龙面板：[whyour/qinglong](https://github.com/whyour/qinglong)
- 原项目参考：[ayoulx/qinglong-app](https://github.com/ayoulx/qinglong-app)
