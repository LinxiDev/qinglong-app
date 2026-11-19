import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'appkey_page.dart';
import 'appkey_viewmodel.dart';

class AppKeyDetailDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> bean;

  const AppKeyDetailDetailPage(this.bean, {super.key});

  @override
  TaskDetailPageState createState() => TaskDetailPageState();
}

class TaskDetailPageState extends ConsumerState<AppKeyDetailDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        backCall: () {
          Navigator.of(context).pop();
        },
        title: widget.bean["name"] ?? "",
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: ref.watch(themeProvider).themeColor.settingBgColor(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ref.watch(themeProvider).themeMode == modeDark
                ? const Color(0xFF2E2E31)
                : const Color(0xFFE6E8EC),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppKeyDetailCell(
              title: 'Client ID	',
              desc: widget.bean >> "client_id",
            ),
            const SizedBox(height: 5),
            AppKeyDetailCell(
              title: 'Client Secret	',
              obtext: true,
              desc: widget.bean >> "client_secret",
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
              child: Text(
                "权限",
                style: TextStyle(
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: Wrap(
                runSpacing: 5,
                spacing: 5,
                children:
                    AppKeyViewModel.getScopeNames(
                          (widget.bean["scopes"] as List<dynamic>?),
                        )
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 5,
                            ),
                            decoration: BoxDecoration(
                              color: ref
                                  .watch(themeProvider)
                                  .themeColor
                                  .descColor(),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              e,
                              maxLines: 1,
                              style: TextStyle(
                                overflow: TextOverflow.ellipsis,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .blackAndWhite(),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 80,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  color: Colors.red,
                  // 红底按钮强制白色文字，避免默认前景色（主题主色）与红底冲突
                  foregroundColor: Colors.white,
                  child: const Text("删 除", style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    _del(context, ref);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _del(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      context: context1,
      useRootNavigator: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确认删除应用 ${widget.bean["name"] ?? ""} 吗"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: Text(
              "确定",
              style: TextStyle(color: ref.watch(themeProvider).primaryColor),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              EasyLoading.show(status: "删除中");
              ref
                  .read(
                    SingleAccountPageState.ofAppKeyProvider(context1)(
                      getProviderName(context1),
                    ),
                  )
                  .delAppKey(context1, getAppKeyId(widget.bean))
                  .then((value) {
                    if (!context1.mounted) {
                      return;
                    }
                    EasyLoading.dismiss();
                    if (mounted) {
                      Navigator.of(context1).pop(true);
                    }
                  })
                  .catchError((_, _) {
                    EasyLoading.dismiss();
                  });
            },
          ),
        ],
      ),
    );
  }
}

class AppKeyDetailCell extends ConsumerStatefulWidget {
  final String title;
  final String? desc;
  final Widget? icon;
  final bool hideDivide;
  final bool obtext;

  const AppKeyDetailCell({
    super.key,
    required this.title,
    this.desc,
    this.icon,
    this.hideDivide = false,
    this.obtext = false,
  });

  @override
  ConsumerState<AppKeyDetailCell> createState() => _AppKeyDetailCellState();
}

class _AppKeyDetailCellState extends ConsumerState<AppKeyDetailCell> {
  late bool _obscure = widget.obtext;

  @override
  Widget build(BuildContext context) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
          child: Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(color: themeColor.titleColor(), fontSize: 16),
              ),
              const SizedBox(width: 30),
              widget.desc != null
                  ? Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: widget.desc ?? ""),
                                );
                                "已复制到剪切板".toast();
                              },
                              child: Text(
                                _obscure ? "*******" : widget.desc!,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: themeColor.descColor(),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          if (widget.obtext) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                              child: Icon(
                                _obscure
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                size: 18,
                                color: themeColor.descColor(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: widget.icon!,
                      ),
                    ),
            ],
          ),
        ),
        widget.hideDivide ? const SizedBox.shrink() : const Divider(height: 1),
      ],
    );
  }
}

extension DynamicEmptyHandle on Map<String, dynamic> {
  String operator >>(Object? key) {
    if (containsKey(key)) {
      dynamic value = this[key];
      if (value != null) {
        if (value is String) {
          if (value.isNotEmpty) {
            return value;
          }
        } else {
          return value.toString();
        }
      }
    }
    return "- -";
  }

  String operator >>>(Object? key) {
    if (containsKey(key)) {
      dynamic value = this[key];
      if (value != null) {
        if (value is String) {
          if (value.isNotEmpty) {
            return value;
          }
        } else {
          return value.toString();
        }
      }
    }
    return "";
  }
}
