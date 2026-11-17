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
