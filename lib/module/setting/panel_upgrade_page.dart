import 'dart:async';
import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/main.dart' show getIt;
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/utils/extension.dart';

/// 面板升级与重启。
///
/// 流程与青龙官方一致：
/// 1. PUT /system/update 启动 download 任务
/// 2. 轮询 GET /system/update-status，直到 status=ready（下载完成）
/// 3. PUT /system/reload {"type":"system"} 应用升级（面板会重启），
///    继续轮询直到 completed / failed
class PanelUpgradePage extends ConsumerStatefulWidget {
  const PanelUpgradePage({super.key});

  @override
  ConsumerState<PanelUpgradePage> createState() => _PanelUpgradePageState();
}

class _PanelUpgradePageState extends ConsumerState<PanelUpgradePage> {
  bool checking = true;
  bool hasNewVersion = false;
  String? latestVersion;
  String? lastLog;

  /// 升级任务状态（官方 getStatus 返回对象的解析结果）
  String upgradeStatus = "idle";
  String? phase;
  String? taskVersion;
  String? error;
  String? taskLog;

  Timer? _poller;
  bool busy = false;

  /// 活动态（与官方 panelUpgrade.cjs 的 active 集合一致）
  static const Set<String> _activeStatus = {
    "starting",
    "running",
    "restarting",
  };

  bool get _isActive => _activeStatus.contains(upgradeStatus);

  @override
  void initState() {
    super.initState();
    _checkUpdate();
    _fetchStatus();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    setState(() {
      checking = true;
    });
    try {
      var response = await SingleAccountPageState.ofApi(context).checkUpdate();
      if (!mounted) {
        return;
      }
      if (response.success) {
        setState(() {
          hasNewVersion = response.bean?.hasNewVersion ?? false;
          latestVersion = response.bean?.lastVersion;
          lastLog = response.bean?.lastLog;
        });
      } else {
        response.message?.toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) {
        setState(() {
          checking = false;
        });
      }
    }
  }

  /// 拉一次升级任务状态
  Future<void> _fetchStatus({bool silent = false}) async {
    try {
      var response = await SingleAccountPageState.ofApi(context)
          .panelUpgradeStatus();
      if (!mounted) {
        return;
      }
      if (response.success) {
        Map<String, dynamic> data = <String, dynamic>{};
        try {
          final dynamic decoded = jsonDecode(response.bean ?? "{}");
          if (decoded is Map<String, dynamic>) {
            final dynamic inner = decoded["data"];
            data = inner is Map<String, dynamic> ? inner : decoded;
          }
        } catch (e) {
          data = <String, dynamic>{};
        }
        setState(() {
          upgradeStatus = data["status"]?.toString() ?? "idle";
          phase = data["phase"]?.toString();
          taskVersion = data["version"]?.toString();
          error = data["error"]?.toString();
          taskLog = data["log"]?.toString();
        });
        _syncPoller();
      } else if (!silent) {
        response.message?.toast();
      }
    } catch (e) {
      // 应用升级/重启期间面板会短暂断连，轮询保持静默
      if (!silent) {
        e.toString().toast();
      }
    }
  }

  /// 活动态时保持 1.5s 轮询，进终态后停止
  void _syncPoller() {
    if (_isActive) {
      _poller ??= Timer.periodic(const Duration(milliseconds: 1500), (_) {
        _fetchStatus(silent: true);
      });
    } else {
      _poller?.cancel();
      _poller = null;
    }
  }

  Future<void> _startDownload() async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
    });
    try {
      var response = await SingleAccountPageState.ofApi(context)
          .startPanelUpgrade();
      if (!mounted) {
        return;
      }
      if (response.success) {
        "已开始下载更新".toast();
        setState(() {
          upgradeStatus = "starting";
        });
        _syncPoller();
        await _fetchStatus(silent: true);
      } else {
        response.message?.toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> _applyUpgrade() async {
    if (busy) {
      return;
    }
    final bool? ok = await showCupertinoDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("应用更新"),
        content: const Text("将重启面板并应用已下载的新版本，期间会短暂无法连接，是否继续？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: Text(
              "继续",
              style: TextStyle(color: ref.watch(themeProvider).primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() {
      busy = true;
    });
    try {
      var response = await SingleAccountPageState.ofApi(context)
          .reloadPanel("system");
      if (!mounted) {
        return;
      }
      if (response.success) {
        "正在应用更新，面板重启中…".toast();
        setState(() {
          upgradeStatus = "starting";
          phase = "verifying";
        });
        _syncPoller();
      } else {
        response.message?.toast();
      }
    } catch (e) {
      // 面板重启会导致请求中断，属于预期
      if (mounted) {
        "面板重启中，请稍后刷新".toast();
        setState(() {
          upgradeStatus = "restarting";
        });
        _syncPoller();
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> _restartPanel() async {
    final bool? ok = await showCupertinoDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("重启面板"),
        content: const Text("面板将重启，期间会短暂无法连接，是否继续？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: Text(
              "重启",
              style: TextStyle(color: ref.watch(themeProvider).primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      var response = await SingleAccountPageState.ofApi(context).reloadPanel();
      if (!mounted) {
        return;
      }
      if (response.success) {
        "面板重启中，请稍后重新连接".toast();
      } else {
        response.message?.toast();
      }
    } catch (e) {
      // 重启断开连接属于预期
      if (mounted) {
        "面板重启中，请稍后重新连接".toast();
      }
    }
  }

  String _statusText() {
    switch (upgradeStatus) {
      case "idle":
        return "空闲";
      case "starting":
        return "准备中";
      case "running":
        if (phase == "downloading") {
          return "下载中";
        }
        if (phase == "verifying") {
          return "校验/应用中";
        }
        return "进行中";
      case "restarting":
        return "重启中";
      case "ready":
        return "下载完成，待应用";
      case "completed":
        return "已完成";
      case "failed":
        return "失败";
      default:
        return upgradeStatus;
    }
  }

  Color _statusColor() {
    if (upgradeStatus == "failed") {
      return const Color(0xffFB5858);
    }
    if (upgradeStatus == "ready" || upgradeStatus == "completed") {
      return ref.watch(themeProvider).primaryColor;
    }
    return ref.watch(themeProvider).themeColor.descColor();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color primary = ref.watch(themeProvider).primaryColor;
    final String currentVersion =
        getIt<SystemBean>(
          instanceName: (SingleAccountPageState.of(context)?.index ?? 0)
              .toString(),
        ).version ??
        "-";

    return Scaffold(
      appBar: const QlAppBar(title: "面板升级"),
      body: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本信息卡片
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: themeColor.settingBgColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF2E2E31)
                      : const Color(0xFFE6E8EC),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        size: 18,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "当前面板版本",
                        style: TextStyle(
                          fontSize: 15,
                          color: themeColor.titleColor(),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currentVersion,
                        style: TextStyle(
                          fontSize: 15,
                          color: themeColor.descColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_down_circle,
                        size: 18,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "最新版本",
                        style: TextStyle(
                          fontSize: 15,
                          color: themeColor.titleColor(),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        checking
                            ? "检测中…"
                            : (hasNewVersion
                                  ? (latestVersion ?? "有新版本")
                                  : "已是最新"),
                        style: TextStyle(
                          fontSize: 15,
                          color: hasNewVersion
                              ? const Color(0xFFEA4D3E)
                              : themeColor.descColor(),
                        ),
                      ),
                    ],
                  ),
                  if (hasNewVersion &&
                      lastLog != null &&
                      lastLog!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF1B1B1D)
                            : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lastLog!,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.descColor(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            // 升级任务状态卡片
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: themeColor.settingBgColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF2E2E31)
                      : const Color(0xFFE6E8EC),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        size: 18,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "升级任务",
                        style: TextStyle(
                          fontSize: 15,
                          color: themeColor.titleColor(),
                        ),
                      ),
                      const Spacer(),
                      if (_isActive)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _statusText(),
                        style: TextStyle(
                          fontSize: 13,
                          color: _statusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (taskVersion != null && taskVersion!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "目标版本：$taskVersion",
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColor.descColor(),
                      ),
                    ),
                  ],
                  if (error != null && error!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "错误：$error",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xffFB5858),
                      ),
                    ),
                  ],
                  if (taskLog != null && taskLog!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF1B1B1D)
                            : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          taskLog!,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            fontFamily: "monospace",
                            color: themeColor.descColor(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            // 操作按钮
            if (hasNewVersion)
              _buildButton(
                title: _isActive ? "下载中…" : "下载更新",
                onTap: (!_isActive && !busy) ? _startDownload : null,
              ),
            if (upgradeStatus == "ready")
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildButton(
                  title: "应用更新并重启",
                  onTap: busy ? null : _applyUpgrade,
                ),
              ),
            const SizedBox(height: 10),
            _buildButton(
              title: "重启面板",
              filled: false,
              onTap: busy ? null : _restartPanel,
            ),
            const SizedBox(height: 10),
            _buildButton(
              title: "重新检查",
              filled: false,
              onTap: checking
                  ? null
                  : () {
                      _checkUpdate();
                      _fetchStatus();
                    },
            ),
            const SizedBox(height: 12),
            Text(
              "说明：下载与应用为两个阶段。下载完成后需点击「应用更新并重启」，"
              "面板会短暂断开，恢复后即完成升级。",
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: themeColor.descColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required VoidCallback? onTap,
    bool filled = true,
  }) {
    final Color primary = ref.watch(themeProvider).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? primary.withValues(alpha: onTap == null ? 0.4 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(color: primary.withValues(alpha: 0.5)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: filled
                ? Colors.white
                : primary.withValues(alpha: onTap == null ? 0.4 : 1),
          ),
        ),
      ),
    );
  }
}
