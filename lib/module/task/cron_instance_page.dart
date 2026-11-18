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
import 'package:qinglong_app/utils/utils.dart';

import '../../main.dart';

/// 任务运行实例（青龙 v2.22+）
///
/// 展示任务的每一轮执行记录：运行中、排队、结束状态、退出码与耗时，
/// 运行中的实例支持强制停止。
class CronInstancePage extends ConsumerStatefulWidget {
  final String cronId;
  final String cronName;

  const CronInstancePage({super.key, required this.cronId, this.cronName = ""});

  @override
  ConsumerState<CronInstancePage> createState() => _CronInstancePageState();
}

class _CronInstancePageState extends ConsumerState<CronInstancePage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> instances = [];

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
    ).cronInstances(widget.cronId);

    if (!mounted) {
      return;
    }

    if (response.success) {
      try {
        final dynamic data = jsonDecode(response.bean ?? "[]");
        instances = (data is List)
            ? data
                  .whereType<Map>()
                  .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                  .toList()
            : [];
      } catch (e) {
        logger.e(e);
      }
    } else {
      error = response.message ?? "获取实例失败";
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> stopInstance(Map<String, dynamic> instance) async {
    final Color primary = ref.read(themeProvider).primaryColor;
    final api = SingleAccountPageState.ofApi(context);
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("停止实例"),
        content: Text("确定停止实例 #${instance["id"]} 吗？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(childContext).pop(false),
          ),
          CupertinoDialogAction(
            child: Text("停止", style: TextStyle(color: primary)),
            onPressed: () => Navigator.of(childContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    EasyLoading.show(status: "停止中");
    final response = await api.stopCronInstance(
      widget.cronId,
      "${instance["id"]}",
    );
    EasyLoading.dismiss();

    if (response.success) {
      "已发送停止指令".toast();
      loadData();
    } else {
      (response.message ?? "停止失败").toast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: widget.cronName.isEmpty ? "运行实例" : widget.cronName,
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              color: ref.watch(themeProvider).primaryColor,
              onRefresh: loadData,
              child: instances.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        Center(
                          child: Text(
                            error ?? "暂无运行实例",
                            textAlign: TextAlign.center,
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
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 30),
                      itemCount: instances.length,
                      itemBuilder: (context, index) {
                        return _buildItem(instances[index]);
                      },
                    ),
            ),
    );
  }

  String _statusText(int status) {
    switch (status) {
      case 0:
        return "运行中";
      case 1:
        return "已完成";
      case 2:
        return "已停止";
      case 3:
        return "异常";
      default:
        return "未知";
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return const Color(0xff20b54f);
      case 1:
        return const Color(0xff1E88E5);
      case 2:
        return const Color(0xffF5A623);
      default:
        return const Color(0xFFFB5858);
    }
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final int status = (item["status"] is num)
        ? (item["status"] as num).toInt()
        : 4;
    final int startedAt = (item["started_at"] is num)
        ? (item["started_at"] as num).toInt()
        : 0;
    final int? finishedAt = (item["finished_at"] is num)
        ? (item["finished_at"] as num).toInt()
        : null;
    final Color color = _statusColor(status);
    final bool running = status == 0;

    String duration = "-";
    if (startedAt > 0) {
      // 面板时间戳可能是秒级也可能是毫秒级，统一换算后再算差值
      final int start = _toMillis(startedAt);
      final int end = finishedAt == null
          ? DateTime.now().millisecondsSinceEpoch
          : _toMillis(finishedAt);
      final int seconds = ((end - start) / 1000).round().clamp(0, 8640000);
      duration = seconds >= 3600
          ? "${seconds ~/ 3600}小时${(seconds % 3600) ~/ 60}分"
          : seconds >= 60
          ? "${seconds ~/ 60}分${seconds % 60}秒"
          : "$seconds秒";
    }

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
                  _statusText(status),
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "#${item["id"] ?? "-"}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
              const Spacer(),
              if (running)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => stopInstance(item),
                  child: Text(
                    "停止",
                    style: TextStyle(
                      fontSize: 13,
                      color: ref.watch(themeProvider).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _row(
            "开始时间",
            startedAt > 0 ? Utils.formatMessageTime(_toMillis(startedAt)) : "-",
          ),
          _row(
            "结束时间",
            finishedAt == null
                ? "-"
                : Utils.formatMessageTime(_toMillis(finishedAt)),
          ),
          _row("耗时", duration),
          _row("退出码", "${item["exit_code"] ?? "-"}"),
          if ((item["pid"] ?? "") != "") _row("PID", "${item["pid"]}"),
        ],
      ),
    );
  }

  /// 秒级时间戳补成毫秒，避免耗时算出天文数字
  int _toMillis(int value) {
    if (value <= 0) return value;
    return value.toString().length <= 10 ? value * 1000 : value;
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: ref.watch(themeProvider).themeColor.descColor(),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: ref.watch(themeProvider).themeColor.titleColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
