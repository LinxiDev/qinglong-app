import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/diff_util.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import '../../../main.dart';

/// 脚本历史版本列表（青龙 v2.23+）
///
/// 每个脚本面板侧最多保留 20 个版本，可查看、对比与还原。
class ScriptHistoryPage extends ConsumerStatefulWidget {
  final String filename;
  final String path;

  const ScriptHistoryPage({
    super.key,
    required this.filename,
    required this.path,
  });

  @override
  ConsumerState<ScriptHistoryPage> createState() => _ScriptHistoryPageState();
}

class _ScriptHistoryPageState extends ConsumerState<ScriptHistoryPage> {
  bool loading = true;
  String? error;
  int limit = 20;
  String currentHash = "";
  List<Map<String, dynamic>> versions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    final HttpResponse<String> response = await SingleAccountPageState.ofApi(
      context,
    ).scriptHistory(widget.filename, widget.path);

    if (!mounted) {
      return;
    }

    if (response.success) {
      try {
        final dynamic data = jsonDecode(response.bean ?? "{}");
        if (data is Map) {
          currentHash = "${data["currentHash"] ?? ""}";
          limit = (data["limit"] is num) ? (data["limit"] as num).toInt() : 20;
          final dynamic list = data["versions"];
          versions = (list is List)
              ? list
                    .whereType<Map>()
                    .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                    .toList()
              : [];
        }
      } catch (e) {
        logger.e(e);
      }
      setState(() {
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        error = response.message ?? "获取历史版本失败";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "历史版本",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              color: ref.watch(themeProvider).primaryColor,
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 30),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  if (error != null)
                    _buildEmpty(error!)
                  else if (versions.isEmpty)
                    _buildEmpty("该脚本暂无历史版本\n面板会在每次保存时保留旧内容")
                  else
                    ...versions.map(_buildVersionCard),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ref.watch(themeProvider).themeColor.settingBordorColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.time,
                size: 18,
                color: ref.watch(themeProvider).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.path.isEmpty
                      ? widget.filename
                      : "${widget.path}/${widget.filename}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ref.watch(themeProvider).themeColor.titleColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "最多保留 $limit 个历史版本，还原前会校验当前内容是否被修改",
            style: TextStyle(
              fontSize: 12,
              color: ref.watch(themeProvider).themeColor.descColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 42,
            color: ref.watch(themeProvider).themeColor.hintColor(),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: ref.watch(themeProvider).themeColor.descColor(),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String source) {
    switch (source) {
      case "baseline":
        return "初始版本";
      case "save":
        return "保存前";
      case "restore":
        return "还原前";
      case "external":
        return "外部变更";
      default:
        return source;
    }
  }

  Widget _buildVersionCard(Map<String, dynamic> item) {
    final bool identical = item["identical"] == true;
    final int size = (item["size"] is num) ? (item["size"] as num).toInt() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ref.watch(themeProvider).themeColor.settingBordorColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context)
                .push(
                  CupertinoPageRoute(
                    builder: (context) => ScriptHistoryDetailPage(
                      filename: widget.filename,
                      path: widget.path,
                      versionId: "${item["id"]}",
                      createdAt: Utils.formatTime2(
                        "${item["createdAt"] ?? ""}",
                      ),
                      sourceLabel: _sourceLabel("${item["source"] ?? ""}"),
                      expectedHash: currentHash,
                    ),
                  ),
                )
                .then((value) {
                  if (value == true) {
                    loadData();
                  }
                });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            Utils.formatTime2("${item["createdAt"] ?? ""}"),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ref
                                  .watch(themeProvider)
                                  .themeColor
                                  .titleColor(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (identical)
                            _badge("与当前相同", const Color(0xff20b54f)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${_sourceLabel("${item["source"] ?? ""}")} · ${_formatSize(size)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: ref
                              .watch(themeProvider)
                              .themeColor
                              .descColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: ref.watch(themeProvider).themeColor.hintColor(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  String _formatSize(int size) {
    if (size < 1024) return "$size B";
    return "${(size / 1024).toStringAsFixed(1)} KB";
  }
}

/// 历史版本详情：支持「对比当前」与「查看内容」两种模式，并可还原。
class ScriptHistoryDetailPage extends ConsumerStatefulWidget {
  final String filename;
  final String path;
  final String versionId;
  final String createdAt;
  final String sourceLabel;
  final String expectedHash;

  const ScriptHistoryDetailPage({
    super.key,
    required this.filename,
    required this.path,
    required this.versionId,
    required this.createdAt,
    required this.sourceLabel,
    required this.expectedHash,
  });

  @override
  ConsumerState<ScriptHistoryDetailPage> createState() =>
      _ScriptHistoryDetailPageState();
}

class _ScriptHistoryDetailPageState
    extends ConsumerState<ScriptHistoryDetailPage> {
  bool loading = true;
  bool showDiff = true;
  String error = "";
  String versionContent = "";
  String currentContent = "";
  List<DiffLine> diffLines = const [];
  Map<String, int> diffStat = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDetail();
    });
  }

  Future<void> loadDetail() async {
    final HttpResponse<String> response = await SingleAccountPageState.ofApi(
      context,
    ).scriptHistoryDetail(widget.filename, widget.path, widget.versionId);

    if (!mounted) {
      return;
    }

    if (!response.success) {
      setState(() {
        loading = false;
        error = response.message ?? "获取版本内容失败";
      });
      return;
    }

    try {
      final dynamic data = jsonDecode(response.bean ?? "{}");
      final dynamic version = data is Map ? data["version"] : null;
      versionContent = "${version is Map ? (version["content"] ?? "") : ""}";
      currentContent = "${data is Map ? (data["current"] ?? "") : ""}";
      diffLines = DiffUtil.diff(versionContent, currentContent);
      diffStat = DiffUtil.stat(diffLines);
    } catch (e) {
      logger.e(e);
      error = "解析版本内容失败";
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> restore() async {
    final Color primary = ref.read(themeProvider).primaryColor;
    final api = SingleAccountPageState.ofApi(context);
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("还原到该版本"),
        content: Text(
          "将使用 ${widget.createdAt} 的历史内容覆盖当前脚本，面板会自动保留当前内容为新的历史版本。",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(childContext).pop(false),
          ),
          CupertinoDialogAction(
            child: Text("还原", style: TextStyle(color: primary)),
            onPressed: () => Navigator.of(childContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    EasyLoading.show(status: "还原中");
    final HttpResponse<String> response = await api.restoreScriptHistory(
      widget.filename,
      widget.path,
      widget.versionId,
      widget.expectedHash,
    );
    EasyLoading.dismiss();

    if (!mounted) {
      return;
    }

    if (response.success) {
      "已还原".toast();
      Navigator.of(context).pop(true);
    } else if (response.code == 409) {
      "脚本已被修改，请刷新后重试".toast();
    } else {
      (response.message ?? "还原失败").toast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "版本详情",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
        actions: [
          loading
              ? const SizedBox.shrink()
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: restore,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Center(
                      child: Text(
                        "还原",
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).appBarTheme.iconTheme?.color,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: ref.watch(themeProvider).themeColor.descColor(),
                  ),
                ),
              ),
            )
          : Column(
              children: [
                _buildToolbar(),
                Expanded(child: showDiff ? _buildDiff() : _buildContent()),
              ],
            ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: ref.watch(themeProvider).themeColor.settingBordorColor(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.createdAt} 的版本",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ref.watch(themeProvider).themeColor.titleColor(),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.sourceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: ref.watch(themeProvider).themeColor.descColor(),
                  ),
                ),
              ],
            ),
          ),
          if (showDiff)
            Text(
              "+${diffStat["add"] ?? 0}  -${diffStat["remove"] ?? 0}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ref.watch(themeProvider).themeColor.descColor(),
              ),
            ),
          const SizedBox(width: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              setState(() {
                showDiff = !showDiff;
              });
            },
            child: Text(
              showDiff ? "查看内容" : "对比差异",
              style: TextStyle(
                fontSize: 13,
                color: ref.watch(themeProvider).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        versionContent,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "monospace",
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildDiff() {
    if (diffLines.isEmpty) {
      return Center(
        child: Text(
          "该版本与当前内容完全一致",
          style: TextStyle(
            fontSize: 13,
            color: ref.watch(themeProvider).themeColor.descColor(),
          ),
        ),
      );
    }

    return Scrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: diffLines.length,
        itemBuilder: (context, index) {
          final DiffLine line = diffLines[index];
          Color background = Colors.transparent;
          Color textColor = ref.watch(themeProvider).themeColor.titleColor();
          String prefix = " ";

          if (line.type == "add") {
            background = const Color(0xff20b54f).withValues(alpha: 0.12);
            textColor = const Color(0xff1B8C3D);
            prefix = "+";
          } else if (line.type == "remove") {
            background = const Color(0xFFFB5858).withValues(alpha: 0.12);
            textColor = const Color(0xffC33B3B);
            prefix = "-";
          }

          return Container(
            color: background,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    "${line.oldLine ?? ""}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.6,
                      color: ref.watch(themeProvider).themeColor.hintColor(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    "${line.newLine ?? ""}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.6,
                      color: ref.watch(themeProvider).themeColor.hintColor(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 16,
                  child: Text(
                    prefix,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.text.isEmpty ? " " : line.text,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      fontFamily: "monospace",
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
