import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/enable_widget.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/empty_widget.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'login_log_bean.dart';

class LoginLogPage extends ConsumerStatefulWidget {
  const LoginLogPage({super.key});

  @override
  LoginLogPageState createState() => LoginLogPageState();
}

class LoginLogPageState extends ConsumerState<LoginLogPage>
    with LazyLoadState<LoginLogPage> {
  List<LoginLogBean> list = [];
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        backCall: () {
          Navigator.of(context).pop();
        },
        title: "登录日志",
      ),
      body: list.isEmpty
          ? (_loaded
                ? const Center(child: EmptyWidget())
                : const Center(child: LoadingWidget()))
          : ListView.separated(
              primary: true,
              itemBuilder: (context, index) {
                LoginLogBean item = list[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ref.watch(themeProvider).themeColor.settingBgColor(),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ref.watch(themeProvider).themeMode == modeDark
                          ? const Color(0xFF2E2E31)
                          : const Color(0xFFE6E8EC),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左列用 Expanded 吸收地址宽度，时间固定在右侧不再被挤错位
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    "${item.address}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ref
                                          .watch(themeProvider)
                                          .themeColor
                                          .titleColor(),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: StatusWidget(
                                    title: item.status == 0 ? "成功" : "失败",
                                    color: item.status == 0
                                        ? ref.watch(themeProvider).primaryColor
                                        : const Color(0xffFB5858),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SelectableText(
                              "${item.ip}",
                              selectionWidthStyle: BoxWidthStyle.max,
                              selectionHeightStyle: BoxHeightStyle.max,
                              style: TextStyle(
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .descColor(),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          Utils.formatMessageTime(item.timestamp ?? 0),
                          style: TextStyle(
                            fontSize: 12,
                            color: ref
                                .watch(themeProvider)
                                .themeColor
                                .descColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                );
              },
              itemCount: list.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Future<void> loadData() async {
    HttpResponse<List<LoginLogBean>> response =
        await SingleAccountPageState.ofApi(context).loginLog();

    if (response.success) {
      if (response.bean == null || response.bean!.isEmpty) {
        "暂无数据".toast();
      }
      list.clear();
      list.addAll(response.bean ?? []);
      _loaded = true;
      setState(() {});
    } else {
      response.message?.toast();
      _loaded = true;
    }
  }

  @override
  void onLazyLoad() {
    loadData();
  }
}
