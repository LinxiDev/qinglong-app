import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/commit_button.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';

/// 系统配置细分项（对齐青龙官方 PUT /system/config/* 接口）。
///
/// 字段名必须与官方一致：
/// cronConcurrency / dependenceProxy / nodeMirror / pythonMirror /
/// linuxMirror / timezone / panelTitle / globalSshKey
class SystemConfigPage extends ConsumerStatefulWidget {
  const SystemConfigPage({super.key});

  @override
  ConsumerState<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends ConsumerState<SystemConfigPage> {
  bool loading = true;

  final TextEditingController _concurrencyController = TextEditingController();
  final TextEditingController _dependenceProxyController =
      TextEditingController();
  final TextEditingController _nodeMirrorController = TextEditingController();
  final TextEditingController _pythonMirrorController = TextEditingController();
  final TextEditingController _linuxMirrorController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _panelTitleController = TextEditingController();
  final TextEditingController _langController = TextEditingController();
  final TextEditingController _logFrequencyController = TextEditingController();
  final TextEditingController _sshKeyController = TextEditingController();

  int? availableCpus;
  int? effectiveConcurrency;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _concurrencyController.dispose();
    _dependenceProxyController.dispose();
    _nodeMirrorController.dispose();
    _pythonMirrorController.dispose();
    _linuxMirrorController.dispose();
    _timezoneController.dispose();
    _panelTitleController.dispose();
    _langController.dispose();
    _logFrequencyController.dispose();
    _sshKeyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var response = await SingleAccountPageState.ofApi(context).systemConfig();
      if (!mounted) {
        return;
      }
      if (response.success) {
        Map<String, dynamic> data = <String, dynamic>{};
        try {
          final dynamic decoded = jsonDecode(response.bean ?? "{}");
          if (decoded is Map<String, dynamic>) {
            /// 面板 GET /system/config 返回的是配置记录：
            /// {id, ip, type, info:{timezone, cronConcurrency, ...}}
            /// 真正的配置项在 info 内，兼容旧版本直接平铺的情况
            final dynamic info = decoded["info"];
            data = info is Map<String, dynamic> ? info : decoded;
          }
        } catch (e) {
          data = <String, dynamic>{};
        }
        setState(() {
          /// 面板把「未设置」的并发数存为 0，展示时按留空处理
          final dynamic concurrency = data["cronConcurrency"];
          final int concurrencyValue = concurrency is num
              ? concurrency.toInt()
              : 0;
          _concurrencyController.text = concurrencyValue > 0
              ? concurrencyValue.toString()
              : "";
          _dependenceProxyController.text =
              data["dependenceProxy"]?.toString() ?? "";
          _nodeMirrorController.text = data["nodeMirror"]?.toString() ?? "";
          _pythonMirrorController.text = data["pythonMirror"]?.toString() ?? "";
          _linuxMirrorController.text = data["linuxMirror"]?.toString() ?? "";
          _timezoneController.text = data["timezone"]?.toString() ?? "";
          _panelTitleController.text = data["panelTitle"]?.toString() ?? "";
          _langController.text = data["lang"]?.toString() ?? "";
          _logFrequencyController.text =
              data["logRemoveFrequency"]?.toString() ?? "";
          _sshKeyController.text = data["globalSshKey"]?.toString() ?? "";
          availableCpus = data["availableCpus"] is num
              ? (data["availableCpus"] as num).toInt()
              : null;
          effectiveConcurrency = data["effectiveCronConcurrency"] is num
              ? (data["effectiveCronConcurrency"] as num).toInt()
              : null;
        });
      } else {
        response.message?.toast();
      }
    } catch (e) {
      e.toString().toast();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// 逐个提交配置项（官方接口一项一个 PUT）
  Future<void> _save() async {
    final String concurrency = _concurrencyController.text.trim();
    if (concurrency.isNotEmpty && int.tryParse(concurrency) == null) {
      "并发数必须是数字".toast();
      return;
    }
    final String logFrequencyText = _logFrequencyController.text.trim();
    if (logFrequencyText.isNotEmpty && int.tryParse(logFrequencyText) == null) {
      "日志保留天数必须是数字".toast();
      return;
    }
    EasyLoading.show(status: "保存中");
    final List<String> failed = [];
    try {
      /// [body] 为 null 表示该项提交 null（清空配置）
      Future<void> put(String key, Map<String, dynamic> body) async {
        try {
          var response = await SingleAccountPageState.ofApi(context)
              .updateSystemConfig(key, body);
          if (!response.success) {
            failed.add(key);
          }
        } catch (e) {
          failed.add(key);
        }
      }

      await put("cron-concurrency", {
        "cronConcurrency": concurrency.isEmpty ? null : int.parse(concurrency),
      });
      await put("dependence-proxy", {
        "dependenceProxy": _dependenceProxyController.text.trim(),
      });
      await put("node-mirror", {
        "nodeMirror": _nodeMirrorController.text.trim(),
      });
      await put("python-mirror", {
        "pythonMirror": _pythonMirrorController.text.trim(),
      });
      await put("linux-mirror", {
        "linuxMirror": _linuxMirrorController.text.trim(),
      });
      await put("timezone", {"timezone": _timezoneController.text.trim()});
      await put("lang", {"lang": _langController.text.trim()});
      await put("log-remove-frequency", {
        "logRemoveFrequency": int.tryParse(logFrequencyText),
      });
      await put("panel-title", {
        "panelTitle": _panelTitleController.text.trim(),
      });
      await put("global-ssh-key", {
        "globalSshKey": _sshKeyController.text.trim(),
      });
    } finally {
      EasyLoading.dismiss();
    }
    if (!mounted) {
      return;
    }
    if (failed.isEmpty) {
      "保存成功".toast();
      _load();
    } else {
      "部分配置保存失败：${failed.join("、")}".toast();
    }
  }

  /// 清理依赖（官方 PUT /system/config/dependence-clean）
  Future<void> _cleanDependence() async {
    const Map<String, String> types = {
      "全部": "",
      "NodeJS": "nodejs",
      "Python3": "python3",
      "Linux": "linux",
    };
    final String? selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context1) {
        return CupertinoActionSheet(
          title: const Text("清理依赖"),
          message: const Text("清理后需要重新安装依赖，确定清理哪一类？"),
          actions: types.entries
              .map(
                (e) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context1).pop(e.value),
                  child: Text(e.key),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context1).pop(),
            child: const Text("取消"),
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    EasyLoading.show(status: "清理中");
    try {
      var response = await SingleAccountPageState.ofApi(context)
          .updateSystemConfig("dependence-clean", {"type": selected});
      EasyLoading.dismiss();
      if (!mounted) {
        return;
      }
      if (response.success) {
        "已提交清理".toast();
      } else {
        response.message?.toast();
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        e.toString().toast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;

    return Scaffold(
      appBar: QlAppBar(
        title: "系统配置",
        actions: [
          if (!loading)
            CommitButton(
              onTap: () {
                _save();
              },
            ),
        ],
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              primary: true,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        _buildField(
                          title: "任务并发数",
                          hint: "留空使用默认值",
                          controller: _concurrencyController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          tip: availableCpus != null
                              ? "可用 CPU：$availableCpus"
                                    "${effectiveConcurrency != null ? "，当前生效：$effectiveConcurrency" : ""}"
                              : null,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "面板标题",
                          hint: "留空使用默认标题",
                          controller: _panelTitleController,
                          maxLength: 100,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "面板语言",
                          hint: "zh 或 en",
                          controller: _langController,
                          maxLength: 10,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "时区",
                          hint: "如 Asia/Shanghai",
                          controller: _timezoneController,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "日志保留天数",
                          hint: "留空表示不自动清理",
                          controller: _logFrequencyController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
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
                        _buildField(
                          title: "依赖安装代理",
                          hint: "如 http://127.0.0.1:1080",
                          controller: _dependenceProxyController,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "Node 镜像源",
                          hint: "如 https://registry.npmmirror.com",
                          controller: _nodeMirrorController,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "Python 镜像源",
                          hint: "如 https://pypi.tuna.tsinghua.edu.cn/simple",
                          controller: _pythonMirrorController,
                        ),
                        _divider(dark),
                        _buildField(
                          title: "Linux 源",
                          hint: "如 https://mirrors.aliyun.com",
                          controller: _linuxMirrorController,
                          tip: "替换源会执行安装脚本，结果显示在面板日志中",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
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
                    child: _buildField(
                      title: "全局 SSH 私钥",
                      hint: "用于仓库拉取的 SSH 私钥（选填）",
                      controller: _sshKeyController,
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _cleanDependence,
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xffEA4D3E).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        "清理依赖",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffEA4D3E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "说明：镜像源 / 时区等配置修改后由面板后台生效，"
                    "部分操作（Linux 源）会在后台执行脚本，结果见面板日志。",
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

  Widget _divider(bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: dark ? const Color(0xFF2E2E31) : const Color(0xFFECEEF1),
      ),
    );
  }

  Widget _buildField({
    required String title,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? tip,
    int maxLines = 1,
    int? maxLength,
  }) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: themeColor.titleColor(),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(fontSize: 14, color: themeColor.titleColor()),
          decoration: InputDecoration(
            hintText: hint,
            counterText: "",
            isDense: true,
          ),
          autofocus: false,
        ),
        if (tip != null && tip.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            tip,
            style: TextStyle(fontSize: 11, color: themeColor.descColor()),
          ),
        ],
      ],
    );
  }
}
