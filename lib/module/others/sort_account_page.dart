import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';

import '../../base/commit_button.dart';
import '../../main.dart';

class SortAccountPage extends ConsumerStatefulWidget {
  const SortAccountPage({super.key});

  @override
  ChangeAccountPageState createState() => ChangeAccountPageState();
}

class ChangeAccountPageState extends ConsumerState<SortAccountPage> {
  List<TokenBean> list = [];

  @override
  void initState() {
    try {
      String json = jsonEncode(
        getIt<MultiAccountUserInfoViewModel>().tokenBeans,
      );
      list.addAll(
        (jsonDecode(json) as List).map((e) => TokenBean.fromJson(e)).toList(),
      );
    } catch (e) {
      // 忽略异常，保持原有行为
    }

    super.initState();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        title: "账号排序",
        actions: [
          CommitButton(
            title: "保存",
            onTap: () {
              getIt<MultiAccountUserInfoViewModel>().resetTokenBeans(list);
              showCupertinoDialog(
                useRootNavigator: false,
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text("保存成功"),
                  content: const Text("重启APP后,新的顺序开始生效"),
                  actions: [
                    CupertinoDialogAction(
                      child: Text(
                        "知道了",
                        style: TextStyle(
                          color: ref.watch(themeProvider).primaryColor,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30, top: 4),
        child: ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (int oldIndex, int newIndex) {
            setState(() {
              //交换数据
              final TokenBean item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
            });
          },
          children: List.generate(list.length, (int index) {
            final TokenBean e = list[index];
            return Container(
              key: ValueKey(e.host ?? index),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ref.watch(themeProvider).themeColor.settingBgColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ref.watch(themeProvider).themeMode == modeDark
                      ? const Color(0xFF2E2E31)
                      : const Color(0xFFE6E8EC),
                ),
              ),
              child: buildCell(e, index),
            );
          }),
        ),
      ),
    );
  }

  Widget buildCell(TokenBean model, int index) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color primary = ref.watch(themeProvider).primaryColor;
    final bool logged = model.token != null && model.token!.isNotEmpty;

    final String alias = (model.alias ?? "").trim().isNotEmpty
        ? model.alias!.trim()
        : "未命名面板";
    final String host = model.host ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // 序号（排序场景用序号比头像更直观）
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: dark ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 别名在上、域名在下
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alias,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: themeColor.titleColor(),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: themeColor.descColor(), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: logged
                  ? primary.withValues(alpha: dark ? 0.22 : 0.10)
                  : (dark ? const Color(0xFF3A2222) : const Color(0xFFFDEEEE)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              logged ? "已登录" : "未登录",
              style: TextStyle(
                color: logged ? primary : const Color(0xFFEA4D3E),
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.line_horizontal_3,
            size: 18,
            color: themeColor.hintColor(),
          ),
        ],
      ),
    );
  }
}
