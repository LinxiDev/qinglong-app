import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';

class TaskLogDetailPage extends ConsumerStatefulWidget {
  final String title;
  final String path;

  const TaskLogDetailPage({super.key, required this.title, required this.path});

  @override
  TaskLogDetailPageState createState() => TaskLogDetailPageState();
}

class TaskLogDetailPageState extends ConsumerState<TaskLogDetailPage>
    with LazyLoadState<TaskLogDetailPage> {
  String? content;

  @override
  Widget build(BuildContext context) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return Scaffold(
      backgroundColor: themeColor.bg2Color(),
      appBar: QlAppBar(
        canBack: true,
        backCall: () {
          Navigator.of(context).pop();
        },
        title: "任务日志详情",
      ),
      body: content == null
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.codeBgColor(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: dark
                        ? const Color(0xFF2E2E31)
                        : const Color(0xFFE6E8EC),
                  ),
                ),
                child: SelectableText(
                  (content == null || content!.isEmpty) ? "暂无数据" : content!,
                  selectionHeightStyle: BoxHeightStyle.max,
                  selectionWidthStyle: BoxWidthStyle.max,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    fontFamily: 'monospace',
                    color: themeColor.titleColor(),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> loadData() async {
    HttpResponse<String> response = await SingleAccountPageState.ofApi(context)
        .taskLogDetail(widget.title, widget.path);

    if (response.success) {
      content = response.bean;
      setState(() {});
    } else {
      response.message?.toast();
    }
  }

  @override
  void onLazyLoad() {
    loadData();
  }
}
