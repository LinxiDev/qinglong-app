## 4.1.0

对齐青龙面板官方接口（v2.23）与功能补齐。

**环境变量**
* 变量标签：列表展示、长按设置（官方 `/envs/labels`）
* 支持导入 JSON 变量文件（`/envs/upload`）
* 搜索改为服务端 `searchValue`

**定时任务**
* 列表分页：20 条/页，滑动到底自动加载
* 状态 Tab 改为官方服务端筛选：全部 / 运行中 / 空闲中 / 已禁用
* 任务行展示「队列中」标记（官方 status=3）
* 任务标签设置（`/crons/labels`）
* 详情进入时拉取最新状态（`/crons/detail`）
* 支持从系统 crontab 增量导入（带重复任务风险提示）

**订阅**
* 修正提交枚举为官方值：`public-repo` / `private-repo` / `file`、
  `crontab` / `interval`、`ssh-key` / `user-pwd`（此前面板无法识别
  定时方式与私有仓库认证方式）
* 新增代理、自动添加/删除任务字段
* 订阅历史日志、服务端搜索
* 删除支持「仅删除」与「连带清理关联任务/脚本」

**脚本 / 依赖**
* 脚本搜索、重命名
* 依赖取消安装（单条与批量）

**仪表盘**
* 新增运行中/排队、系统资源、标签统计、今日成功/失败排行
* 趋势支持 7/14/30 天，首屏关键数据优先渲染

**系统 / 用户**
* 系统配置支持面板语言、日志保留天数
* 数据清理读取官方 `info` 字段并回填
* 兼容官方纯文本/流式响应（镜像源切换）
* 两步验证管理、退出登录调用官方 logout
* IP 黑名单格式校验（IPv4/IPv6，不支持网段）
* 应用密钥 Secret 显示/隐藏开关

**修复**
* 环境变量编辑不再强制启用
* iCloud 同步失败不再写时间戳；变量按名称 upsert、订阅按 alias/url
  去重、配置保存校验结果
* 日志设置改用 `/system/config/log-remove-frequency`
* 应用密钥重置在应用登录下走 `/open`
* 移除未使用/官方不存在的接口封装

**移除**
* 任务自定义视图（App 不需要）

## 4.0.0

技术栈整体升级：

* Flutter SDK 升级至 3.50.0（Dart 3.14）
* 全面迁移至官方新 UI 包 `material_ui` / `cupertino_ui`
* 依赖全部升级至最新主版本：riverpod 3、dio 5、webview_flutter 4、share_plus 13、
  file_picker 13、local_auth 3、extended_text 15、flutter_slidable 5、get_it 9 等
* 移除不再维护且不兼容 Dart 3 的依赖：`json_conversion`、`highlight`、`dio_log`、`json_table`、
  `flutter_animator`、`launch_review`、`move_to_background`、`icloud_storage`、`get`、`drag_and_drop_lists`
* 替换为：`in_app_review`、`move_to_bg`、`icloud_storage_plus`，并自研抖动动画、JSON 表格与代码高亮降级方案
* Android 构建体系迁移至 Gradle 9.5 + AGP 9.3 + Kotlin 2.4（Kotlin DSL），
  编译目标 Java 17，最低支持 Android 7.0
* iOS 最低系统版本提升至 15.0
* 适配新版 Flutter API：`PopScope`、`TextScaler`、`WidgetState`、`withValues`、`TabBarThemeData`、
  `MediaQueryData.fromView`、`SharePlus`、`onReorderItem` 等

新增功能（对齐青龙面板 v2.22 ~ v2.25）：

* 运行概览：今日运行/成功率/平均耗时、近 7 日趋势、耗时与执行次数排行
* 脚本历史版本：列表、与当前内容逐行对比、一键还原（带并发修改校验）
* 脚本运行 / 停止 / 重命名
* 任务运行实例：查看每轮执行的状态、耗时、退出码，支持强制停止
* 定时规则预览：新增/编辑任务时直接预览未来 3 次执行时间与时区
* 通知日志：面板通知审计记录，支持按成功/失败筛选
* 数据清理：运行实例与统计数据保留天数、依赖缓存清理、数据库压缩与预览
* IP 黑名单管理
* 环境变量置顶 / 取消置顶 / 重命名
* 依赖刷新与取消安装
* 应用图标更换为青龙官方 Logo，并适配暗色主题（白色剪影版本）
* 原生启动图支持亮/暗色两套

其他：

* 新增单元与编译冒烟测试（版本解析、文本差异、JSON 表格、全量依赖图编译）
* 修复环境变量拖拽排序在新的 `onReorderItem` 语义下的索引偏移问题

## 2.6.3

* 修改环境变量最后一条可能无法展示完整的问题
* 修改首页可能会出现大量空白的问题
* 移除App内的消息推送功能
* Android端部分机型输入法选择文本可能会崩溃，这是框架的问题，等官方解决了再更新吧
