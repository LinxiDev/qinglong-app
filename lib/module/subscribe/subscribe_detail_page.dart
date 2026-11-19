import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/cupertino_sheet.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/module/subscribe/add_subscribe_page.dart';
import 'package:qinglong_app/module/task/intime_log/intime_subscribe_log_page.dart';
import 'package:qinglong_app/utils/utils.dart';

class SubscribeDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> taskBean;
  final bool hideAppbar;

  const SubscribeDetailPage(
    this.taskBean, {
    super.key,
    this.hideAppbar = false,
  });

  @override
  TaskDetailPageState createState() => TaskDetailPageState();
}

class TaskDetailPageState extends ConsumerState<SubscribeDetailPage>
    with LazyLoadState<SubscribeDetailPage> {
  Type type = Type.public;
  CronType cronType = CronType.cron;
  PullType pullType = PullType.privateKey;
  String intervalUnit = "天";

  void _enableSubscribe(BuildContext context, int disabled) {
    ref
        .read(
          SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context),
          ),
        )
        .enableSubscribe(context, widget.taskBean["id"], disabled);
  }

  /// 按官方字段解析详情（此前 type/pullType 等写死为默认值，
  /// 导致私有仓库/单文件/间隔调度的详情展示错误）
  void _parseBean() {
    final Map bean = widget.taskBean;
    final String typeName = (bean["type"] ?? "").toString();
    type = typeName == "private-repo" || typeName == "private"
        ? Type.private
        : typeName == "file" || typeName == "single"
        ? Type.single
        : Type.public;

    final String scheduleType = (bean["schedule_type"] ?? "").toString();
    cronType = scheduleType == "interval" ? CronType.interval : CronType.cron;

    final String pull = (bean["pull_type"] ?? "").toString();
    pullType = pull == "user-pwd" || pull == "userName"
        ? PullType.userName
        : PullType.privateKey;

    final dynamic interval = bean["interval_schedule"];
    if (interval is Map) {
      final String unit = (interval["type"] ?? "days").toString();
      intervalUnit =
          {"days": "天", "hours": "小时", "minutes": "分钟", "seconds": "秒"}[unit] ??
          "天";
    }
  }

  @override
  Widget build(BuildContext context) {
    _parseBean();
    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        backCall: () {
          Navigator.of(context).pop();
        },
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: () {
              showMoreOperate(context, [
                CupertinoSheer(
                  title: (widget.taskBean["status"] ?? 0) == 1 ? "运行" : "停止运行",
                  onTap: () async {
                    if (widget.taskBean["status"] == 1) {
                      await _startCron(context, ref, true);
                    } else {
                      _stopCron(context, ref);
                    }
                  },
                ),
                addDivider(),
                CupertinoSheer(
                  title: "查看日志",
                  onTap: () {
                    showLog();
                  },
                ),
                addDivider(),
                CupertinoSheer(
                  title: "编辑",
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                AddSubscribePage(taskBean: widget.taskBean),
                          ),
                        )
                        .then((value) {
                          if (!context.mounted) {
                            return;
                          }
                          if (value != null && value == true) {
                            if (context.mounted) {
                              ref
                                  .read(
                                    SingleAccountPageState.ofSubscribeProvider(
                                      context,
                                    )(getProviderName(context)),
                                  )
                                  .loadData(context);
                            }
                          }
                        });
                  },
                ),
                addDivider(),
                CupertinoSheer(
                  title: (widget.taskBean["is_disabled"] ?? 0) == 1
                      ? "启用"
                      : "禁用",
                  onTap: () {
                    _enableSubscribe(
                      context,
                      (widget.taskBean["is_disabled"] ?? 0),
                    );
                  },
                ),
              ]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).appBarTheme.iconTheme?.color,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
        title: "订阅详情",
      ),
      body: isLoading
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              primary: true,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SubscribeDetailCell(
                      title: '名称',
                      desc: widget.taskBean >> "name",
                    ),
                    SubscribeDetailCell(
                      title: '类型',
                      desc: widget.taskBean >> "type",
                    ),
                    SubscribeDetailCell(
                      title: '链接',
                      desc: widget.taskBean >> "url",
                    ),
                    Visibility(
                      visible: type == Type.public,
                      child: _buildOpenPub(),
                    ),
                    Visibility(
                      visible: type == Type.single,
                      child: _buildSingle(),
                    ),
                    Visibility(
                      visible: type == Type.private,
                      child: _buildPrivatePub(),
                    ),
                    SubscribeDetailCell(
                      title: '定时类型',
                      desc: widget.taskBean >> "schedule_type",
                    ),
                    Visibility(
                      visible: cronType == CronType.cron,
                      child: SubscribeDetailCell(
                        title: "定时规则",
                        desc: widget.taskBean >> "schedule",
                      ),
                    ),
                    Visibility(
                      visible: cronType == CronType.interval,
                      child: SubscribeDetailCell(
                        title: "定时规则",
                        desc: _intervalDesc(),
                      ),
                    ),
                    Visibility(
                      visible: type != Type.single,
                      child: SubscribeDetailCell(
                        title: "白名单",
                        desc: widget.taskBean >> "whitelist",
                      ),
                    ),
                    Visibility(
                      visible: type != Type.single,
                      child: SubscribeDetailCell(
                        title: "黑名单",
                        desc: widget.taskBean >> "blacklist",
                      ),
                    ),
                    Visibility(
                      visible: type != Type.single,
                      child: SubscribeDetailCell(
                        title: "依赖文件",
                        desc: widget.taskBean >> "dependences",
                      ),
                    ),
                    Visibility(
                      visible: type != Type.single,
                      child: SubscribeDetailCell(
                        title: "文件后缀",
                        desc: widget.taskBean >> "extensions",
                      ),
                    ),
                    Visibility(
                      visible: type != Type.single,
                      child: SubscribeDetailCell(
                        title: "执行前",
                        desc: widget.taskBean >> "sub_before",
                      ),
                    ),
                    Visibility(
                      visible: type != Type.single,
                      child: SubscribeDetailCell(
                        title: "执行后",
                        desc: widget.taskBean >> "sub_after",
                      ),
                    ),
                    SubscribeDetailCell(
                      title: "运行状态",
                      desc: widget.taskBean["status"] == 0
                          ? "正在运行"
                          : widget.taskBean["status"] == 3
                          ? "排队中"
                          : "空闲",
                    ),
                    SubscribeDetailCell(
                      title: "订阅状态",
                      desc: (widget.taskBean["is_disabled"] ?? 0) == 1
                          ? "已禁用"
                          : "已启用",
                    ),
                    SubscribeDetailCell(
                      title: "日志",
                      desc: widget.taskBean >> "log_path",
                      taped: () {
                        showLog();
                      },
                    ),
                    SubscribeDetailCell(
                      title: "创建时间",
                      desc: widget.taskBean >> "createdAt",
                      hideDivide: true,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 80,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          color: Colors.red,
                          // 红底按钮强制白色文字，避免默认前景色（主题主色）与红底冲突
                          foregroundColor: Colors.white,
                          child: const Text(
                            "删 除",
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            delSubscribe(context, ref);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void delSubscribe(BuildContext context1, WidgetRef ref) {
    showCupertinoDialog(
      useRootNavigator: false,
      context: context1,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("确认删除"),
        content: Text("确认删除订阅 ${widget.taskBean["name"] ?? ""} 吗"),
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
            onPressed: () async {
              if (!context1.mounted) {
                return;
              }
              Navigator.of(context).pop();
              await ref
                  .read(
                    SingleAccountPageState.ofSubscribeProvider(context1)(
                      getProviderName(context1),
                    ),
                  )
                  .delSubscribe(context1, widget.taskBean["id"]);
              if (context1.mounted) {
                Navigator.of(context1).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildRadioButton(
    String title,
    bool isCheck, {
    GestureTapCallback? onTap,
    flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Row(
          children: [
            Image.asset(
              isCheck
                  ? "assets/images/icon_check.png"
                  : "assets/images/icon_uncheck.png",
              width: 16,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 5),
            Text(title),
          ],
        ),
      ),
    );
  }

  void showLog() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => InTimeSubscribeLogPage(
          widget.taskBean["id"],
          true,
          widget.taskBean["name"] ?? "",
        ),
      ),
    );
  }

  Future<void> _startCron(BuildContext context, WidgetRef ref, bool log) async {
    await ref
        .read(
          SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context),
          ),
        )
        .runCrons(context, widget.taskBean["id"]);
    if (log) {
      Future.delayed(const Duration(milliseconds: 250), () {
        showLog();
      });
    }
  }

  void _stopCron(BuildContext context, WidgetRef ref) {
    ref
        .read(
          SingleAccountPageState.ofSubscribeProvider(context)(
            getProviderName(context),
          ),
        )
        .stopCrons(context, widget.taskBean["id"]);
  }

  Widget _buildSingle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [],
      ),
    );
  }

  Widget _buildOpenPub() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubscribeDetailCell(title: '分支', desc: widget.taskBean >> "branch"),
        ],
      ),
    );
  }

  Map get _pullOption {
    final dynamic option = widget.taskBean["pull_option"];
    return option is Map ? option : <String, dynamic>{};
  }

  String _intervalDesc() {
    final dynamic interval = widget.taskBean["interval_schedule"];
    if (interval is Map) {
      final String value = (interval["value"] ?? "").toString();
      return "每 $value$intervalUnit";
    }
    final String raw = (interval ?? "").toString();
    return raw.isEmpty ? "-" : raw;
  }

  Widget _buildPrivatePub() {
    final Map option = _pullOption;
    final String privateKey =
        (option["privateKey"] ?? option["private_key"] ?? "").toString();
    final String username = (option["username"] ?? "").toString();
    final String password = (option["password"] ?? "").toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          SubscribeDetailCell(title: '分支', desc: widget.taskBean >> "branch"),
          const SizedBox(height: 15),
          SubscribeDetailCell(
            title: '拉取方式',
            desc: pullType == PullType.privateKey ? "私钥 (SSH)" : "用户名密码",
          ),
          const SizedBox(height: 15),
          Visibility(
            visible: pullType == PullType.privateKey,
            child: SubscribeDetailCell(
              title: '私钥',
              desc: privateKey.isEmpty ? "未配置" : "已配置",
            ),
          ),
          Visibility(
            visible: pullType == PullType.userName,
            child: SubscribeDetailCell(
              title: '用户名',
              desc: username.isEmpty ? "未配置" : username,
            ),
          ),
          Visibility(
            visible: pullType == PullType.userName,
            child: const SizedBox(height: 15),
          ),
          Visibility(
            visible: pullType == PullType.userName,
            child: SubscribeDetailCell(
              title: "密码/Token",
              desc: password.isEmpty ? "未配置" : "已配置",
            ),
          ),
        ],
      ),
    );
  }

  bool isLoading = true;

  @override
  void onLazyLoad() {
    isLoading = false;
    setState(() {});
  }
}

class SubscribeDetailCell extends ConsumerWidget {
  final String title;
  final String? desc;
  final Widget? icon;
  final bool hideDivide;
  final Function? taped;

  const SubscribeDetailCell({
    super.key,
    required this.title,
    this.desc,
    this.icon,
    this.hideDivide = false,
    this.taped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 30),
              desc != null
                  ? Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SelectableText(
                          desc!,
                          textAlign: TextAlign.right,
                          selectionHeightStyle: BoxHeightStyle.max,
                          selectionWidthStyle: BoxWidthStyle.max,
                          onTap: () {
                            if (taped != null) {
                              taped!();
                            }
                          },
                          style: TextStyle(
                            color: ref
                                .watch(themeProvider)
                                .themeColor
                                .descColor(),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: icon!,
                      ),
                    ),
            ],
          ),
        ),
        hideDivide ? const SizedBox.shrink() : const Divider(height: 1),
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
