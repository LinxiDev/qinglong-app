import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../main.dart';

/// 运行概览（对应面板 v2.22+ 的仪表盘统计接口）
///
/// 展示今日成功/失败、近 7 天趋势、耗时榜与执行次数榜。
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool loading = true;

  Map<String, dynamic> overview = {};
  List<Map<String, dynamic>> trend = [];
  List<Map<String, dynamic>> topTime = [];
  List<Map<String, dynamic>> topCount = [];
  Map<String, dynamic> runtime = {};
  Map<String, dynamic> systemInfo = {};
  List<Map<String, dynamic>> labels = [];
  List<Map<String, dynamic>> successes = [];
  List<Map<String, dynamic>> failures = [];
  int trendDays = 7;

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
      });
    }

    final Api api = SingleAccountPageState.ofApi(context);

    final List<HttpResponse<String>> responses = await Future.wait([
      api.dashboardOverview(),
      api.dashboardTrend(days: trendDays),
      api.dashboardTopTime(),
      api.dashboardTopCount(),
      api.dashboardRuntime(),
      api.dashboardLabels(),
      api.dashboardSystem(),
      api.dashboardSuccesses(),
      api.dashboardFailures(),
    ]);

    if (!mounted) {
      return;
    }

    overview = _decodeMap(responses[0]);
    trend = _decodeList(responses[1]);
    topTime = _decodeList(responses[2]);
    topCount = _decodeList(responses[3]);
    runtime = _decodeMap(responses[4]);
    labels = _decodeList(responses[5]);
    systemInfo = _decodeMap(responses[6]);
    successes = _decodeList(responses[7]);
    failures = _decodeList(responses[8]);

    setState(() {
      loading = false;
    });

    if (!responses[0].success) {
      responses[0].message.toast();
    }
  }

  Map<String, dynamic> _decodeMap(HttpResponse<String> response) {
    if (!response.success || response.bean == null || response.bean!.isEmpty) {
      return {};
    }
    try {
      final dynamic data = jsonDecode(response.bean!);
      if (data is Map) {
        return data.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (e) {
      logger.e(e);
    }
    return {};
  }

  List<Map<String, dynamic>> _decodeList(HttpResponse<String> response) {
    if (!response.success || response.bean == null || response.bean!.isEmpty) {
      return [];
    }
    try {
      final dynamic data = jsonDecode(response.bean!);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
    } catch (e) {
      logger.e(e);
    }
    return [];
  }

  num _num(String key) {
    final dynamic value = overview[key];
    if (value is num) return value;
    return num.tryParse("${value ?? ""}") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "运行概览",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              EasyLoading.show(status: "刷新中");
              loadData().then((_) => EasyLoading.dismiss());
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Center(child: Icon(CupertinoIcons.refresh, size: 22)),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              color: ref.watch(themeProvider).primaryColor,
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
                children: [
                  _buildTodayCard(),
                  const SizedBox(height: 15),
                  _buildMetricRow(),
                  const SizedBox(height: 15),
                  _buildTrendCard(),
                  const SizedBox(height: 15),
                  _buildRankCard(
                    title: "耗时排行",
                    empty: "今日暂无执行记录",
                    data: topTime,
                    trailingBuilder: (item) => "${item["avgTime"] ?? 0} 秒",
                  ),
                  const SizedBox(height: 15),
                  _buildRankCard(
                    title: "执行次数排行",
                    empty: "今日暂无执行记录",
                    data: topCount,
                    trailingBuilder: (item) => "${item["runCount"] ?? 0} 次",
                  ),
                  const SizedBox(height: 15),
                  _buildRankCard(
                    title: "今日成功排行",
                    empty: "今日暂无成功记录",
                    data: successes,
                    trailingBuilder: (item) => "${item["successCount"] ?? 0} 次",
                  ),
                  const SizedBox(height: 15),
                  _buildRankCard(
                    title: "今日失败排行",
                    empty: "今日暂无失败记录",
                    data: failures,
                    trailingBuilder: (item) => "${item["failCount"] ?? 0} 次",
                  ),
                  const SizedBox(height: 15),
                  _buildRuntimeCard(),
                  const SizedBox(height: 15),
                  _buildSystemCard(),
                  const SizedBox(height: 15),
                  _buildLabelsCard(),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "统计基于面板本地数据，仅统计今日 00:00 至当前",
                      style: TextStyle(
                        fontSize: 12,
                        color: ref.watch(themeProvider).themeColor.descColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTodayCard() {
    final int todayRuns = _num("todayRuns").toInt();
    final int todaySuccess = _num("todaySuccess").toInt();
    final int todayFail = _num("todayFail").toInt();
    final String successRate = "${overview["successRate"] ?? 0}";

    final Color primary = ref.watch(themeProvider).primaryColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "今日运行",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$todayRuns",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  "次",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "成功率 $successRate%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "平均耗时 ${overview["avgTime"] ?? 0}s",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: todaySuccess == 0 ? 0 : todaySuccess,
                    child: Container(color: Colors.white),
                  ),
                  Expanded(
                    flex: todayFail == 0 ? 0 : todayFail,
                    child: Container(color: const Color(0xFFFFC7C7)),
                  ),
                  Expanded(
                    flex: (todayRuns - todaySuccess - todayFail) <= 0
                        ? 0
                        : (todayRuns - todaySuccess - todayFail),
                    child: Container(color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(Colors.white, "成功 $todaySuccess"),
              const SizedBox(width: 16),
              _legend(const Color(0xFFFFC7C7), "失败 $todayFail"),
              const SizedBox(width: 16),
              _legend(Colors.white24, "其他"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildMetricRow() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            "任务总数",
            "${_num("total").toInt()}",
            CupertinoIcons.square_list,
            const Color(0xff1E88E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            "已启用",
            "${_num("enabled").toInt()}",
            CupertinoIcons.play_circle,
            const Color(0xff20b54f),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            "运行中",
            "${_triggerRunning()}",
            CupertinoIcons.bolt_fill,
            const Color(0xffF5A623),
          ),
        ),
      ],
    );
  }

  int _triggerRunning() {
    final dynamic triggers = overview["triggers"];
    if (triggers is Map) {
      final dynamic running = triggers["running"] ?? triggers["runningCount"];
      if (running is num) return running.toInt();
      return int.tryParse("${running ?? 0}") ?? 0;
    }
    if (triggers is num) return triggers.toInt();
    return 0;
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: ref.watch(themeProvider).themeColor.settingBordorColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ref.watch(themeProvider).themeColor.titleColor(),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: ref.watch(themeProvider).themeColor.descColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    int maxValue = 1;
    for (final item in trend) {
      final int total = (item["total"] is num)
          ? (item["total"] as num).toInt()
          : 0;
      if (total > maxValue) maxValue = total;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
      decoration: BoxDecoration(
        color: ref.watch(themeProvider).themeColor.settingBordorColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "近 $trendDays 日趋势",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
              const Spacer(),
              ...[7, 14, 30].map(
                (days) => CupertinoButton(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onPressed: () {
                    if (trendDays == days) {
                      return;
                    }
                    setState(() {
                      trendDays = days;
                    });
                    loadData();
                  },
                  child: Text(
                    "$days天",
                    style: TextStyle(
                      fontSize: 12,
                      color: trendDays == days
                          ? ref.watch(themeProvider).primaryColor
                          : ref.watch(themeProvider).themeColor.descColor(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: trend.isEmpty
                ? Center(
                    child: Text(
                      "暂无数据",
                      style: TextStyle(
                        fontSize: 12,
                        color: ref.watch(themeProvider).themeColor.descColor(),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trend.map((item) {
                      final int success = (item["success"] is num)
                          ? (item["success"] as num).toInt()
                          : 0;
                      final int fail = (item["fail"] is num)
                          ? (item["fail"] as num).toInt()
                          : 0;
                      final int total = (item["total"] is num)
                          ? (item["total"] as num).toInt()
                          : 0;
                      final double maxHeight = 104;
                      final double totalHeight = maxHeight * (total / maxValue);
                      final double successHeight = total == 0
                          ? 0
                          : totalHeight * (success / total);
                      final double failHeight = total == 0
                          ? 0
                          : totalHeight * (fail / total);

                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              total == 0 ? "" : "$total",
                              style: TextStyle(
                                fontSize: 10,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .descColor(),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 14,
                              height: totalHeight < 3 && total > 0
                                  ? 3
                                  : totalHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xffF3F4F6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (failHeight > 0)
                                    Container(
                                      height: failHeight,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFB5858),
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  if (successHeight > 0)
                                    Container(
                                      height: successHeight,
                                      decoration: BoxDecoration(
                                        color: ref
                                            .watch(themeProvider)
                                            .primaryColor,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(
                                            failHeight > 0 ? 0 : 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${item["date"] ?? ""}",
                              style: TextStyle(
                                fontSize: 10,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .descColor(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  int _intOf(Map<String, dynamic> data, String key) {
    final dynamic value = data[key];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse("${value ?? ""}") ?? 0;
  }

  String _stringOf(Map<String, dynamic> data, String key) {
    final dynamic value = data[key];
    return value == null ? "-" : "$value";
  }

  String _formatUptime(dynamic value) {
    final int seconds = value is num
        ? value.toInt()
        : int.tryParse("$value") ?? 0;
    if (seconds <= 0) {
      return "-";
    }
    final int days = seconds ~/ 86400;
    final int hours = (seconds % 86400) ~/ 3600;
    return days > 0 ? "$days 天 $hours 小时" : "$hours 小时";
  }

  Widget _buildSimpleCard(String title, List<List<String>> rows) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
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
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  "暂无数据",
                  style: TextStyle(
                    fontSize: 12,
                    color: ref.watch(themeProvider).themeColor.descColor(),
                  ),
                ),
              ),
            )
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row[0],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: ref
                              .watch(themeProvider)
                              .themeColor
                              .titleColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      row[1],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ref.watch(themeProvider).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRuntimeCard() {
    final List running = runtime["running"] is List
        ? runtime["running"] as List
        : [];
    final List<List<String>> rows = [
      ["运行中实例", "${_intOf(runtime, "runningCount")}"],
      ["排队中", "${_intOf(runtime, "queuedCount")}"],
      ...running
          .take(5)
          .map(
            (e) => <String>[
              e is Map ? "${e["name"] ?? "-"}" : "-",
              "${e is Map ? (e["elapsed"] ?? 0) : 0} 秒",
            ],
          ),
    ];
    return _buildSimpleCard("运行中任务", rows);
  }

  Widget _buildSystemCard() {
    final List loadAvg = systemInfo["loadAvg"] is List
        ? systemInfo["loadAvg"] as List
        : [];
    final List<List<String>> rows = [
      ["平台", _stringOf(systemInfo, "platform")],
      ["CPU 核心", _stringOf(systemInfo, "cpus")],
      ["内存占用", "${_stringOf(systemInfo, "memUsagePercent")}%"],
      ["负载", loadAvg.isEmpty ? "-" : loadAvg.map((e) => "$e").join(" / ")],
      ["运行时长", _formatUptime(systemInfo["uptime"])],
    ];
    return _buildSimpleCard("系统资源", rows);
  }

  Widget _buildLabelsCard() {
    final List<List<String>> rows = labels
        .take(8)
        .map(
          (item) => <String>[
            "${item["label"] ?? "未分类"}",
            "${item["todayRuns"] ?? 0} 次 / ${item["successRate"] ?? 0}%",
          ],
        )
        .toList();
    return _buildSimpleCard("标签统计", rows);
  }

  Widget _buildRankCard({
    required String title,
    required String empty,
    required List<Map<String, dynamic>> data,
    required String Function(Map<String, dynamic>) trailingBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 6),
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
          const SizedBox(height: 6),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  empty,
                  style: TextStyle(
                    fontSize: 12,
                    color: ref.watch(themeProvider).themeColor.descColor(),
                  ),
                ),
              ),
            )
          else
            ...data.map((item) {
              final int rank = (item["rank"] is num)
                  ? (item["rank"] as num).toInt()
                  : data.indexOf(item) + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? ref.watch(themeProvider).primaryColor
                            : ref
                                  .watch(themeProvider)
                                  .themeColor
                                  .segmentedUnCheckBg(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "$rank",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3
                              ? Colors.white
                              : ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .titleColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${item["name"] ?? "-"}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: ref
                              .watch(themeProvider)
                              .themeColor
                              .titleColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trailingBuilder(item),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ref.watch(themeProvider).themeColor.descColor(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
