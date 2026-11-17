import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/utils.dart';

import '../../main.dart';

/// 通知审计日志（青龙 v2.24+）
///
/// 展示面板与脚本发送通知的结果、渠道、失败原因，方便排查通知未送达的问题。
class NotifyLogPage extends ConsumerStatefulWidget {
  const NotifyLogPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotifyLogPage> createState() => _NotifyLogPageState();
}

class _NotifyLogPageState extends ConsumerState<NotifyLogPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> list = [];
  String filter = "全部";

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
    ).notifyLog();

    if (!mounted) return;

    if (response.success) {
      try {
        final dynamic data = jsonDecode(response.bean ?? "[]");
        list = (data is List)
            ? data
                  .whereType<Map>()
                  .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                  .toList()
            : [];
      } catch (e) {
        logger.e(e);
      }
    } else {
      error = response.message ?? "获取通知日志失败";
    }

    setState(() {
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filtered {
    if (filter == "全部") return list;
    if (filter == "失败") {
      return list.where((e) => !_isSuccess(e["status"])).toList();
    }
    return list.where((e) => _isSuccess(e["status"])).toList();
  }

  /// 面板侧 status 为数字枚举：0 成功、1 失败；同时兼容字符串形式
  bool _isSuccess(dynamic status) {
    if (status is num) return status.toInt() == 0;
    final String value = "${status ?? ""}".toLowerCase();
    return value == "success" ||
        value == "0" ||
        value == "ok" ||
        value == "true";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "通知日志",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: loadData,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Center(child: Icon(CupertinoIcons.refresh, size: 22)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: loading
                ? const Center(child: CupertinoActivityIndicator())
                : RefreshIndicator(
                    color: ref.watch(themeProvider).primaryColor,
                    onRefresh: loadData,
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                              ),
                              Center(
                                child: Text(
                                  error ?? "暂无通知记录",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ref
                                        .watch(themeProvider)
                                        .themeColor
                                        .descColor(),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 30),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _buildItem(filtered[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    final List<String> options = ["全部", "失败", "成功"];
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
      child: Row(
        children: options.map((e) {
          final bool selected = filter == e;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  filter = e;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? ref.watch(themeProvider).primaryColor
                      : ref
                            .watch(themeProvider)
                            .themeColor
                            .segmentedUnCheckBg(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? Colors.white
                        : ref.watch(themeProvider).themeColor.titleColor(),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final bool success = _isSuccess(item["status"]);
    final Color color = success
        ? const Color(0xff20b54f)
        : const Color(0xFFFB5858);
    final int timestamp = (item["timestamp"] is num)
        ? (item["timestamp"] as num).toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  success ? "成功" : "失败",
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${item["title"] ?? item["notifyType"] ?? "通知"}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ref.watch(themeProvider).themeColor.titleColor(),
                  ),
                ),
              ),
              if (timestamp > 0)
                Text(
                  Utils.formatMessageTime(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: ref.watch(themeProvider).themeColor.descColor(),
                  ),
                ),
            ],
          ),
          if ("${item["content"] ?? ""}".isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "${item["content"]}",
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: ref.watch(themeProvider).themeColor.titleColor(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _tag("渠道 ${item["notifyType"] ?? "-"}"),
              _tag("来源 ${item["source"] == "script" ? "脚本" : "系统"}"),
              if ("${item["taskId"] ?? ""}".isNotEmpty)
                _tag("任务 ${item["taskId"]}"),
              if ("${item["scriptName"] ?? ""}".isNotEmpty)
                _tag("${item["scriptName"]}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: ref.watch(themeProvider).themeColor.descColor(),
      ),
    );
  }
}
