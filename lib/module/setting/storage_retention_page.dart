import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../main.dart';

/// 数据保留与清理（青龙 v2.22+）
///
/// 支持配置运行实例 / 统计数据的保留天数，清理依赖缓存、压缩数据库，
/// 清理前可先预览将被删除的条目数量。
class StorageRetentionPage extends ConsumerStatefulWidget {
  const StorageRetentionPage({Key? key}) : super(key: key);

  @override
  ConsumerState<StorageRetentionPage> createState() =>
      _StorageRetentionPageState();
}

class _StorageRetentionPageState extends ConsumerState<StorageRetentionPage> {
  bool loading = true;

  int instanceDays = 30;
  int statDays = 90;
  bool cleanNode = false;
  bool cleanPython = false;
  bool compactDatabase = false;

  Map<String, dynamic>? preview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConfig();
    });
  }

  Future<void> loadConfig() async {
    final HttpResponse<String> response = await SingleAccountPageState.ofApi(
      context,
    ).systemConfig();

    if (!mounted) return;

    if (response.success) {
      try {
        final dynamic data = jsonDecode(response.bean ?? "{}");
        if (data is Map) {
          final dynamic instance = data["runningInstanceRetentionDays"];
          final dynamic stat = data["cronStatRetentionDays"];
          if (instance is num) instanceDays = instance.toInt();
          if (stat is num) statDays = stat.toInt();
        }
      } catch (e) {
        logger.e(e);
      }
    }

    setState(() {
      loading = false;
    });
  }

  Map<String, dynamic> get _payload => {
    "runningInstanceRetentionDays": instanceDays,
    "cronStatRetentionDays": statDays,
    "dependenceCacheTypes": [if (cleanNode) "node", if (cleanPython) "python3"],
    "compactDatabase": compactDatabase,
  };

  Future<void> saveConfig() async {
    EasyLoading.show(status: "保存中");
    final response = await SingleAccountPageState.ofApi(context)
        .retentionUpdateConfig({
          "runningInstanceRetentionDays": instanceDays,
          "cronStatRetentionDays": statDays,
        });
    EasyLoading.dismiss();

    if (response.success) {
      "已保存，面板会按新策略自动清理".toast();
    } else {
      (response.message ?? "保存失败").toast();
    }
  }

  Future<void> doPreview() async {
    EasyLoading.show(status: "统计中");
    final response = await SingleAccountPageState.ofApi(context)
        .retentionPreview(_payload);
    EasyLoading.dismiss();

    if (!mounted) return;

    if (!response.success) {
      (response.message ?? "预览失败").toast();
      return;
    }

    try {
      final dynamic data = jsonDecode(response.bean ?? "{}");
      if (data is Map) {
        setState(() {
          preview = data.map((k, v) => MapEntry(k.toString(), v));
        });
      }
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> doCleanup() async {
    final Color primary = ref.read(themeProvider).primaryColor;
    final api = SingleAccountPageState.ofApi(context);
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("确认清理"),
        content: const Text("将删除超出保留期的运行实例与统计数据，此操作不可恢复，确定继续吗？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(childContext).pop(false),
          ),
          CupertinoDialogAction(
            child: Text("清理", style: TextStyle(color: primary)),
            onPressed: () => Navigator.of(childContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    EasyLoading.show(status: "清理中");
    final response = await api.retentionCleanup(_payload);
    EasyLoading.dismiss();

    if (!mounted) return;

    if (response.success) {
      "清理完成".toast();
      setState(() {
        preview = null;
      });
      loadConfig();
    } else {
      (response.message ?? "清理失败").toast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "数据清理",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
              children: [
                _buildCard(
                  title: "保留策略",
                  children: [
                    _buildStepper(
                      title: "运行实例保留天数",
                      desc: "0 表示不自动清理，超期实例与触发记录会被删除",
                      value: instanceDays,
                      onChanged: (value) {
                        setState(() {
                          instanceDays = value;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildStepper(
                      title: "统计数据保留天数",
                      desc: "运行概览与趋势所依赖的日统计数据",
                      value: statDays,
                      onChanged: (value) {
                        setState(() {
                          statDays = value;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: ref.watch(themeProvider).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: saveConfig,
                            child: const Text(
                              "保存策略",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildCard(
                  title: "手动清理",
                  children: [
                    _buildCheckbox(
                      title: "清理 Node 依赖缓存",
                      value: cleanNode,
                      onChanged: (value) {
                        setState(() {
                          cleanNode = value;
                          preview = null;
                        });
                      },
                    ),
                    _buildCheckbox(
                      title: "清理 Python 依赖缓存",
                      value: cleanPython,
                      onChanged: (value) {
                        setState(() {
                          cleanPython = value;
                          preview = null;
                        });
                      },
                    ),
                    _buildCheckbox(
                      title: "压缩数据库",
                      value: compactDatabase,
                      onChanged: (value) {
                        setState(() {
                          compactDatabase = value;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: ref
                                .watch(themeProvider)
                                .themeColor
                                .segmentedUnCheckBg(),
                            borderRadius: BorderRadius.circular(8),
                            onPressed: doPreview,
                            child: Text(
                              "预览",
                              style: TextStyle(
                                fontSize: 14,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .titleColor(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFFFB5858),
                            borderRadius: BorderRadius.circular(8),
                            onPressed: doCleanup,
                            child: const Text(
                              "立即清理",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (preview != null) ...[
                  const SizedBox(height: 15),
                  _buildCard(
                    title: "预览结果",
                    children: [
                      _previewRow("运行实例", preview!["runningInstances"]),
                      _previewRow("触发记录", preview!["triggers"]),
                      _previewRow("统计数据", preview!["cronStats"]),
                      _previewRow(
                        "依赖缓存大小",
                        _formatBytes(preview!["dependenceCacheBytes"]),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  "提示：清理仅影响历史记录与缓存，不会删除任务、脚本、环境变量与配置。",
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: ref.watch(themeProvider).themeColor.descColor(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _previewRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: ref.watch(themeProvider).themeColor.titleColor(),
              ),
            ),
          ),
          Text(
            "${value ?? 0}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ref.watch(themeProvider).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(dynamic value) {
    final int bytes = (value is num) ? value.toInt() : 0;
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / 1024 / 1024).toStringAsFixed(1)} MB";
    }
    return "${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB";
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ref.watch(themeProvider).themeColor.settingBordorColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ref.watch(themeProvider).themeColor.titleColor(),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String title,
    required String desc,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
            ),
            _stepButton(CupertinoIcons.minus, () {
              if (value > 0) onChanged(value - 1);
            }),
            SizedBox(
              width: 52,
              child: Text(
                "$value",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
            ),
            _stepButton(CupertinoIcons.plus, () {
              if (value < 3650) onChanged(value + 1);
            }),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(
            fontSize: 11,
            color: ref.watch(themeProvider).themeColor.descColor(),
          ),
        ),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: ref.watch(themeProvider).themeColor.segmentedUnCheckBg(),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: ref.watch(themeProvider).themeColor.titleColor(),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              value
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              size: 18,
              color: value
                  ? ref.watch(themeProvider).primaryColor
                  : ref.watch(themeProvider).themeColor.hintColor(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
