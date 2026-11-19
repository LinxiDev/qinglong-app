import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/utils/extension.dart';

/// 任务视图管理（对齐官方 /crons/views）
///
/// 视图 = 名称 + 过滤条件(filters) + 排序(sorts) + 条件关系，
/// 面板任务页通过视图快速切换筛选后的任务集合。
class TaskViewPage extends ConsumerStatefulWidget {
  const TaskViewPage({super.key});

  @override
  ConsumerState<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends ConsumerState<TaskViewPage> {
  bool loading = true;
  List<Map<String, dynamic>> views = [];

  @override
  void initState() {
    super.initState();
    loadViews();
  }

  Future<void> loadViews() async {
    final response = await SingleAccountPageState.ofApi(context).cronViews();
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
        views = result;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      (response.message ?? "读取视图失败").toast();
    }
  }

  bool _disabled(Map<String, dynamic> view) {
    final dynamic value = view["isDisabled"] ?? view["is_disabled"];
    return value == 1 || value == true;
  }

  int? _id(Map<String, dynamic> view) {
    final dynamic id = view["id"];
    return id is num ? id.toInt() : int.tryParse("$id");
  }

  String _filtersText(Map<String, dynamic> view) {
    final dynamic filters = view["filters"];
    if (filters == null) {
      return "";
    }
    if (filters is String) {
      return filters;
    }
    return jsonEncode(filters);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    return Scaffold(
      appBar: QlAppBar(
        title: "任务视图",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: () => showEditor(),
            child: Icon(
              CupertinoIcons.add,
              size: 24,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              itemCount: views.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> view = views[index];
                final bool disabled = _disabled(view);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.settingBgColor(),
                    borderRadius: BorderRadius.circular(12),
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
                          Expanded(
                            child: Text(
                              "${view["name"] ?? "未命名视图"}",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: themeColor.titleColor(),
                              ),
                            ),
                          ),
                          if (disabled)
                            const Text(
                              "已禁用",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xffFB5858),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filtersText(view).isEmpty
                            ? "无条件（全部任务）"
                            : _filtersText(view),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.descColor(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _action(disabled ? "启用" : "禁用", () => toggle(view)),
                          _action("编辑", () => showEditor(view)),
                          _action("删除", () => deleteView(view), danger: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _action(String text, VoidCallback onTap, {bool danger = false}) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      onPressed: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: danger
              ? const Color(0xffEA4D3E)
              : ref.watch(themeProvider).primaryColor,
        ),
      ),
    );
  }

  Future<void> toggle(Map<String, dynamic> view) async {
    final int? id = _id(view);
    if (id == null) {
      return;
    }
    final api = SingleAccountPageState.ofApi(context);
    final response = _disabled(view)
        ? await api.enableCronView([id])
        : await api.disableCronView([id]);
    if (!mounted) {
      return;
    }
    if (response.success) {
      "已更新".toast();
      loadViews();
    } else {
      (response.message ?? "操作失败").toast();
    }
  }

  Future<void> deleteView(Map<String, dynamic> view) async {
    final int? id = _id(view);
    if (id == null) {
      return;
    }
    final bool? ok = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确定删除视图 ${view["name"] ?? ""} 吗"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消"),
            onPressed: () => Navigator.of(childContext).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("删除"),
            onPressed: () => Navigator.of(childContext).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    final response = await SingleAccountPageState.ofApi(context)
        .deleteCronView([id]);
    if (!mounted) {
      return;
    }
    if (response.success) {
      "已删除".toast();
      loadViews();
    } else {
      (response.message ?? "删除失败").toast();
    }
  }

  Future<void> showEditor([Map<String, dynamic>? view]) async {
    final TextEditingController nameController = TextEditingController(
      text: view == null ? "" : "${view["name"] ?? ""}",
    );
    final TextEditingController filterController = TextEditingController(
      text: view == null ? "" : _filtersText(view),
    );
    final String? saved = await showCupertinoDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: Text(view == null ? "新建视图" : "编辑视图"),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: nameController,
                placeholder: "视图名称",
                autofocus: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: filterController,
                placeholder: "过滤条件 JSON，如 [{\"field\":\"status\",\"type\":\"In\",\"value\":[0,1]}]",
                maxLines: 4,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消"),
            onPressed: () => Navigator.of(childContext).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("保存"),
            onPressed: () => Navigator.of(childContext).pop(
              jsonEncode({
                "name": nameController.text.trim(),
                "filters": filterController.text.trim(),
              }),
            ),
          ),
        ],
      ),
    );
    if (saved == null || !mounted) {
      return;
    }
    final Map<String, dynamic> payload = jsonDecode(saved);
    final String name = (payload["name"] ?? "").toString();
    if (name.isEmpty) {
      "请输入视图名称".toast();
      return;
    }
    final String filtersText = (payload["filters"] ?? "").toString().trim();
    List<dynamic> filters = [];
    if (filtersText.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(filtersText);
        if (parsed is List) {
          filters = parsed;
        } else {
          "过滤条件必须是 JSON 数组".toast();
          return;
        }
      } catch (e) {
        "过滤条件不是合法 JSON".toast();
        return;
      }
    }
    EasyLoading.show(status: "保存中");
    final api = SingleAccountPageState.ofApi(context);
    final Map<String, dynamic> body = {
      "name": name,
      "filters": filters,
      "sorts": view?["sorts"] ?? [],
      "filterRelation": view?["filterRelation"] ?? "and",
    };
    final int? id = view == null ? null : _id(view);
    if (id != null) {
      body["id"] = id;
    }
    final response = id == null
        ? await api.addCronView(body)
        : await api.updateCronView(body);
    EasyLoading.dismiss();
    if (!mounted) {
      return;
    }
    if (response.success) {
      "已保存".toast();
      loadViews();
    } else {
      (response.message ?? "保存失败").toast();
    }
  }
}
