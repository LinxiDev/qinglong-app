import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:share_plus/share_plus.dart';

/// 订阅历史日志（官方 GET /subscriptions/:id/logs + /logs/detail）
class SubscribeLogsPage extends ConsumerStatefulWidget {
  final int subscriptionId;
  final String title;
  final String alias;

  const SubscribeLogsPage({
    super.key,
    required this.subscriptionId,
    required this.title,
    this.alias = "",
  });

  @override
  ConsumerState<SubscribeLogsPage> createState() => _SubscribeLogsPageState();
}

class _SubscribeLogsPageState extends ConsumerState<SubscribeLogsPage> {
  bool loading = true;
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final response = await SingleAccountPageState.ofApi(context)
        .subscribeLogs(widget.subscriptionId);
    if (!mounted) {
      return;
    }
    if (response.success) {
      List<Map<String, dynamic>> result = [];
      try {
        final dynamic decoded = jsonDecode(response.bean ?? "[]");
        dynamic list = decoded;
        if (decoded is Map && decoded["data"] is List) {
          list = decoded["data"];
        }
        if (list is List) {
          result = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (e) {
        logger.e(e);
      }
      setState(() {
        logs = result;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      (response.message ?? "读取日志列表失败").toast();
    }
  }

  String _name(Map<String, dynamic> item) {
    return (item["name"] ?? item["title"] ?? item["file"] ?? "").toString();
  }

  Future<void> openLog(Map<String, dynamic> item) async {
    final String name = _name(item);
    if (name.isEmpty) {
      return;
    }
    final response = await SingleAccountPageState.ofApi(context)
        .logDetailChunk(name, widget.alias);
    if (!mounted) {
      return;
    }
    if (!response.success) {
      (response.message ?? "读取日志失败").toast();
      return;
    }
    final String content = response.bean ?? "";
    if (!mounted) {
      return;
    }
    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: Text(name, style: const TextStyle(fontSize: 15)),
        content: Container(
          height: 360,
          width: double.maxFinite,
          padding: const EdgeInsets.only(top: 10),
          child: SingleChildScrollView(
            child: SelectableText(
              content.isEmpty ? "日志为空" : content,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("分享"),
            onPressed: () {
              SharePlus.instance.share(ShareParams(text: content));
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("关闭"),
            onPressed: () => Navigator.of(childContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return Scaffold(
      appBar: QlAppBar(
        title: "${widget.title} · 历史日志",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : logs.isEmpty
          ? Center(
              child: Text(
                "暂无历史日志",
                style: TextStyle(fontSize: 13, color: themeColor.descColor()),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> item = logs[index];
                final dynamic size = item["size"];
                final dynamic time = item["mtime"] ?? item["time"];
                return GestureDetector(
                  onTap: () => openLog(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.settingBgColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(item).isEmpty ? "未命名日志" : _name(item),
                          style: TextStyle(
                            fontSize: 14,
                            color: themeColor.titleColor(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (size != null) "$size B",
                            if (time != null) "$time",
                          ].join(" · "),
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColor.descColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
