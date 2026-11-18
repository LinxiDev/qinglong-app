import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:qinglong_app/base/commit_button.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/upload_script_widget.dart';
import 'package:qinglong_app/module/others/scripts/script_upload_page.dart';
import 'package:qinglong_app/module/subscribe/add_subscribe_page.dart';
import 'package:qinglong_app/module/task/task_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../config/config_detail_page.dart';
import '../home/system_bean.dart';
import 'task_payload.dart';

/// 新增 / 编辑任务，覆盖面板侧的完整字段：
/// 定时类型、多条定时规则、实例模式、工作目录、日志名称、执行前后命令、队列控制。
class AddTaskPage extends ConsumerStatefulWidget {
  final TaskBean? taskBean;
  final bool hideUploadFile;

  const AddTaskPage({
    super.key,
    this.taskBean,
    required this.hideUploadFile,
  });

  @override
  ConsumerState<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends ConsumerState<AddTaskPage>
    with LazyLoadState<AddTaskPage> {
  late TaskBean taskBean;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _cronController = TextEditingController();
  final TextEditingController _workDirController = TextEditingController();
  final TextEditingController _logNameController = TextEditingController();
  final TextEditingController _beforeController = TextEditingController();
  final TextEditingController _afterController = TextEditingController();
  final TextEditingController _maxQueueController = TextEditingController();
  final TextEditingController _catchupController = TextEditingController();

  /// 额外定时规则，可增删
  final List<TextEditingController> _extraControllers = [];

  String scheduleType = ScheduleType.normal;
  int allowMultipleInstances = 0;
  bool skipIfPending = false;

  FocusNode focusNode = FocusNode();

  bool get isEdit => taskBean.sId != null && taskBean.sId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.taskBean != null) {
      taskBean = widget.taskBean!;
      _nameController.text = taskBean.name ?? "";
      _commandController.text = taskBean.command ?? "";
      final String type = taskBean.scheduleType;
      scheduleType = type;
      _cronController.text = type == ScheduleType.normal
          ? (taskBean.schedule ?? "")
          : "";
      _workDirController.text = taskBean.workDir ?? "";
      _logNameController.text = taskBean.logName ?? "";
      _beforeController.text = taskBean.taskBefore ?? "";
      _afterController.text = taskBean.taskAfter ?? "";
      _maxQueueController.text = (taskBean.maxQueueWait ?? 0) > 0
          ? "${taskBean.maxQueueWait}"
          : "";
      _catchupController.text = (taskBean.catchupSeconds ?? 0) > 0
          ? "${taskBean.catchupSeconds}"
          : "";
      allowMultipleInstances = taskBean.allowMultipleInstances ?? 0;
      skipIfPending = taskBean.skipIfPending ?? false;
      for (final rule in taskBean.extraSchedules) {
        _extraControllers.add(TextEditingController(text: rule));
      }
    } else {
      taskBean = TaskBean();
    }
  }

  @override
  void dispose() {
    for (final controller in _extraControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        actions: [
          CommitButton(
            onTap: () {
              submit();
            },
          ),
        ],
        title: isEdit ? "编辑任务" : "新增任务",
      ),
      body: SingleChildScrollView(
        primary: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _section(
              children: [
                const TitleWidget("名称", required: true),
                const SizedBox(height: 10),
                TextField(
                  focusNode: focusNode,
                  controller: _nameController,
                  maxLines: 3,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(hintText: "请输入名称"),
                  autofocus: false,
                ),
                const SizedBox(height: 15),
                const TitleWidget("命令", required: true),
                const SizedBox(height: 10),
                TextField(
                  controller: _commandController,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(hintText: "请输入命令"),
                  autofocus: false,
                ),
              ],
            ),
            _section(
              children: [
                const TitleWidget("定时类型", required: true),
                const SizedBox(height: 10),
                _buildScheduleTypeRow(),
                if (scheduleType == ScheduleType.normal) ...[
                  const SizedBox(height: 15),
                  const TitleWidget("定时规则", required: true),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cronController,
                    minLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: "秒(可选) 分 时 天 月 周",
                    ),
                    autofocus: false,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          try {
                            var cron = _cronController.text.replaceAll(
                              " ",
                              "_",
                            );
                            await launchUrl(
                              Uri.tryParse("https://crontab.guru/#$cron")!,
                            );
                          } catch (e) {
                            // 忽略异常，保持原有行为
                          }
                        },
                        child: Text(
                          "在线测试",
                          style: TextStyle(
                            fontSize: 12,
                            color: ref.watch(themeProvider).primaryColor,
                          ),
                        ),
                      ),
                      if (_canPreviewCron) ...[
                        const SizedBox(width: 18),
                        GestureDetector(
                          onTap: previewCron,
                          child: Text(
                            "预览下次执行",
                            style: TextStyle(
                              fontSize: 12,
                              color: ref.watch(themeProvider).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const TitleWidget("额外定时规则"),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: addExtraSchedule,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.add,
                                size: 14,
                                color: ref.watch(themeProvider).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "添加",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ref.watch(themeProvider).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_extraControllers.isEmpty)
                    Text(
                      "同一任务可配置多条定时规则，例如工作日与周末不同的时间",
                      style: TextStyle(
                        fontSize: 11,
                        color: ref.watch(themeProvider).themeColor.descColor(),
                      ),
                    ),
                  ...List.generate(_extraControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _extraControllers[index],
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: "额外规则 ${index + 1}",
                              ),
                              autofocus: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _extraControllers.removeAt(index).dispose();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                CupertinoIcons.delete,
                                size: 18,
                                color: const Color(0xFFFB5858),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(
                    scheduleType == ScheduleType.once
                        ? "手动运行：任务只在手动点击运行时执行，不再按时间调度"
                        : "开机运行：面板启动时自动执行一次",
                    style: TextStyle(
                      fontSize: 11,
                      color: ref.watch(themeProvider).themeColor.descColor(),
                    ),
                  ),
                ],
              ],
            ),
            _section(
              children: [
                const TitleWidget("实例模式"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInstanceChip(0, "单实例", "运行中跳过新触发"),
                    const SizedBox(width: 10),
                    _buildInstanceChip(1, "多实例", "允许并发执行"),
                  ],
                ),
                const SizedBox(height: 15),
                const TitleWidget("工作目录"),
                const SizedBox(height: 10),
                TextField(
                  controller: _workDirController,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: "留空自动检测，或输入相对/绝对路径",
                  ),
                  autofocus: false,
                ),
                const SizedBox(height: 15),
                const TitleWidget("日志名称"),
                const SizedBox(height: 10),
                TextField(
                  controller: _logNameController,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: "留空自动生成，/dev/null 丢弃日志",
                  ),
                  autofocus: false,
                ),
                const SizedBox(height: 15),
                const TitleWidget("执行前"),
                const SizedBox(height: 10),
                TextField(
                  controller: _beforeController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "运行任务前执行的命令，如 python3 xxx.py",
                  ),
                  autofocus: false,
                ),
                const SizedBox(height: 15),
                const TitleWidget("执行后"),
                const SizedBox(height: 10),
                TextField(
                  controller: _afterController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "运行任务后执行的命令",
                  ),
                  autofocus: false,
                ),
              ],
            ),
            if (scheduleType == ScheduleType.normal && _supportQueueConfig)
              _section(
                children: [
                  const TitleWidget("队列与补跑"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "上一次仍在排队或运行时跳过本次",
                              style: TextStyle(
                                fontSize: 13,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .titleColor(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "单实例任务生效，避免重复触发",
                              style: TextStyle(
                                fontSize: 11,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .descColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: skipIfPending,
                        activeTrackColor: ref.watch(themeProvider).primaryColor,
                        onChanged: (value) {
                          setState(() {
                            skipIfPending = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const TitleWidget("最长排队时间（秒）"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maxQueueController,
                    keyboardType: TextInputType.number,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "0 表示不限时",
                    ),
                    autofocus: false,
                  ),
                  const SizedBox(height: 12),
                  const TitleWidget("重启后补跑时长（秒）"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catchupController,
                    keyboardType: TextInputType.number,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "0 表示关闭补跑",
                    ),
                    autofocus: false,
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: !widget.hideUploadFile,
                    child: UploadScriptWidget(
                      key: fileKey,
                      nameCallBack: (name) async {
                        _nameController.text = name ?? "";
                        if (name == null || name.isEmpty) {
                          _commandController.text = "";
                          _cronController.text = "";
                        } else {
                          String command =
                              "task ${fileKey.currentState?.scriptPath}${(fileKey.currentState != null && fileKey.currentState!.scriptPath.isNotEmpty) ? p.separator : ""}${fileKey.currentState?.getFileName()}";

                          _commandController.text = command;

                          String data =
                              await fileKey.currentState?.file
                                  ?.readAsString() ??
                              "";

                          _cronController.text =
                              ScriptUploadPageState.getCronString(data, name) ??
                              "";
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      padding: const EdgeInsets.only(top: 15),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ref.watch(themeProvider).themeColor.settingBordorColor(),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildScheduleTypeRow() {
    const List<String> types = [
      ScheduleType.normal,
      ScheduleType.once,
      ScheduleType.boot,
    ];
    return Row(
      children: types.map((type) {
        final bool selected = scheduleType == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: type == ScheduleType.boot ? 0 : 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  scheduleType = type;
                });
              },
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? ref.watch(themeProvider).primaryColor
                      : ref
                          .watch(themeProvider)
                          .themeColor
                          .segmentedUnCheckBg(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ScheduleType.label(type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? Colors.white
                        : ref.watch(themeProvider).themeColor.titleColor(),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstanceChip(int value, String title, String desc) {
    final bool selected = allowMultipleInstances == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            allowMultipleInstances = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? ref.watch(themeProvider).primaryColor.withValues(alpha: 0.1)
                : ref.watch(themeProvider).themeColor.segmentedUnCheckBg(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: 1,
              color: selected
                  ? ref.watch(themeProvider).primaryColor
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? ref.watch(themeProvider).primaryColor
                      : ref.watch(themeProvider).themeColor.titleColor(),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 10,
                  color: ref.watch(themeProvider).themeColor.descColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addExtraSchedule() {
    setState(() {
      _extraControllers.add(TextEditingController());
    });
  }

  /// 定时规则预览接口在较新面板才提供，低版本不展示入口
  bool get _canPreviewCron {
    try {
      return getIt<SystemBean>(
        instanceName: (SingleAccountPageState.of(context)?.index ?? 0)
            .toString(),
      ).isUpperVersion2_24_0();
    } catch (e) {
      return false;
    }
  }

  /// 队列/补跑相关字段是 2.24+ 才有的能力，低版本面板会直接拒绝未知字段
  bool get _supportQueueConfig {
    try {
      return getIt<SystemBean>(
        instanceName: (SingleAccountPageState.of(context)?.index ?? 0)
            .toString(),
      ).isUpperVersion2_24_0();
    } catch (e) {
      return false;
    }
  }

  /// 调用面板的定时规则预览接口，展示未来几次执行时间
  void previewCron() async {
    final String schedule = _cronController.text.trim();
    if (schedule.isEmpty) {
      "请先填写定时规则".toast();
      return;
    }

    EasyLoading.show(status: "计算中");
    final response = await SingleAccountPageState.ofApi(
      context,
    ).cronPreview(schedule);
    EasyLoading.dismiss();

    if (!mounted) return;

    if (!response.success) {
      (response.message ?? "定时规则格式有误").toast();
      return;
    }

    List<String> times = [];
    String timezone = "";
    try {
      final dynamic data = jsonDecode(response.bean ?? "{}");
      if (data is Map) {
        timezone = "${data["timezone"] ?? ""}";
        final dynamic list = data["times"];
        if (list is List) {
          times = list.map((e) => "$e").toList();
        }
      }
    } catch (e) {
      logger.e(e);
    }

    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("下次执行时间"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timezone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  "时区：$timezone",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff999999),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            ...(times.isEmpty
                ? [const Text("面板未返回结果")]
                : times.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(e, style: const TextStyle(fontSize: 13)),
                    ),
                  )),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("知道了"),
            onPressed: () => Navigator.of(childContext).pop(),
          ),
        ],
      ),
    );
  }

  GlobalKey<UploadScriptWidgetState> fileKey = GlobalKey();

  void submit() async {
    if (_nameController.text.isEmpty) {
      "任务名称不能为空".toast();
      return;
    }
    if (_commandController.text.isEmpty) {
      "命令不能为空".toast();
      return;
    }
    if (scheduleType == ScheduleType.normal && _cronController.text.isEmpty) {
      "定时规则不能为空".toast();
      return;
    }
    if (scheduleType == ScheduleType.normal) {
      for (final controller in _extraControllers) {
        if (controller.text.trim().isEmpty) {
          "额外定时规则不能为空，请删除空白项".toast();
          return;
        }
      }
    }

    commitReal();
  }

  Map<String, dynamic> buildPayload() {
    final String schedule = scheduleType == ScheduleType.normal
        ? _cronController.text.trim()
        : ScheduleType.value(scheduleType);

    final List<String> extras = _extraControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final bool normal = scheduleType == ScheduleType.normal;

    return buildTaskPayload(
      name: _nameController.text.trim(),
      command: _commandController.text.trim(),
      schedule: schedule,
      allowMultipleInstances: allowMultipleInstances,
      workDir: _workDirController.text.trim(),
      logName: _logNameController.text.trim(),
      taskBefore: _beforeController.text.trim(),
      taskAfter: _afterController.text.trim(),
      includeExtraSchedules: normal,
      extraSchedules: extras,
      skipIfPending: normal && _supportQueueConfig ? skipIfPending : null,
      maxQueueWait: int.tryParse(_maxQueueController.text.trim()) ?? 0,
      catchupSeconds: int.tryParse(_catchupController.text.trim()) ?? 0,
    );
  }

  void commitReal() async {
    try {
      hideKeyboardFocus();
      if (fileKey.currentState != null && fileKey.currentState!.file != null) {
        String content = await fileKey.currentState!.file!.readAsString();
        HttpResponse<NullResponse> responseS = await SingleAccountPageState
            // ignore: use_build_context_synchronously
            .ofApi(context)
            .addScript(
              fileKey.currentState?.getFileName() ??
                  _commandController.text.split(" ").last,
              fileKey.currentState?.scriptPath ?? "",
              content,
            );
        if (!responseS.success) {
          responseS.message.toast();
          return;
        }
      }

      final Map<String, dynamic> payload = buildPayload();

      // 同步所有字段回本地 bean，避免二次编辑时用旧值覆盖
      taskBean.name = payload["name"];
      taskBean.command = payload["command"];
      taskBean.schedule = payload["schedule"];
      taskBean.allowMultipleInstances =
          payload["allow_multiple_instances"] as int?;
      taskBean.workDir = payload["work_dir"] as String?;
      taskBean.logName = payload["log_name"] as String?;
      taskBean.taskBefore = payload["task_before"] as String?;
      taskBean.taskAfter = payload["task_after"] as String?;
      taskBean.extraSchedules =
          (payload["extra_schedules"] as List?)
              ?.map((e) => "${e["schedule"]}")
              .toList() ??
          [];
      taskBean.skipIfPending = payload["skip_if_pending"] as bool?;
      taskBean.maxQueueWait = payload["max_queue_wait"] as int?;
      taskBean.catchupSeconds = payload["catchup_seconds"] as int?;

      await EasyLoading.show(status: " 提交中");
      HttpResponse<NullResponse> response = await SingleAccountPageState.ofApi(
        // ignore: use_build_context_synchronously
        context,
      ).addTask(
        payload,
        id: taskBean.id,
        nId: taskBean.nId,
      );

      // 老版本面板不支持部分高级字段（Joi 会拒绝未知字段），
      // 这里降级为只提交基础字段，避免整个操作失败。
      if (!response.success && _isValidationError(response)) {
        final Map<String, dynamic> basic = <String, dynamic>{
          "name": payload["name"],
          "command": payload["command"],
          "schedule": payload["schedule"],
        };
        final HttpResponse<NullResponse> retry = await SingleAccountPageState
            // ignore: use_build_context_synchronously
            .ofApi(context)
            .addTask(basic, id: taskBean.id, nId: taskBean.nId);
        if (retry.success) {
          "当前面板版本不支持部分高级设置，已仅保存基础信息".toast();
          response = retry;
        }
      }

      await EasyLoading.dismiss();
      if (response.success) {
        isEdit ? "修改成功".toast() : "新增成功".toast();
        ref
            .read(
              // ignore: use_build_context_synchronously
              SingleAccountPageState.ofTaskProvider(context)(
                // ignore: use_build_context_synchronously
                getProviderName(context),
              ),
            )
            // ignore: use_build_context_synchronously
            .updateBean(context, taskBean);
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        response.message.toast();
      }
    } catch (e) {
      e.toString().toast();
      EasyLoading.dismiss();
    }
  }

  /// 面板返回的字段校验失败（老版本不认识新字段）
  bool _isValidationError(HttpResponse<NullResponse> response) {
    final String message = (response.message ?? "").toLowerCase();
    return message.contains("validation failed") ||
        message.contains("not allowed") ||
        message.contains("不允许");
  }

  @override
  void onLazyLoad() {
    if (widget.hideUploadFile) {
      focusNode.requestFocus();
    }
  }
}
