import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/commit_button.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/label_tag.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/module/env/env_bean.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../config/config_detail_page.dart';
import '../subscribe/add_subscribe_page.dart';

class AddEnvPage extends ConsumerStatefulWidget {
  final EnvBean? envBean;

  const AddEnvPage({super.key, this.envBean});

  @override
  ConsumerState<AddEnvPage> createState() => _AddEnvPageState();
}

class _AddEnvPageState extends ConsumerState<AddEnvPage>
    with LazyLoadState<AddEnvPage> {
  late EnvBean envBean;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _labelInputController = TextEditingController();
  final FocusNode _labelFocusNode = FocusNode();
  FocusNode focusNode = FocusNode();

  /// 标签区是否处于「新建输入」状态（官方：+ 新建 → 点开变输入框）
  bool _addingLabel = false;

  /// 新建时是否按换行拆分值（官方新建弹窗的「拆分」开关，默认开启）
  bool _splitValue = true;

  /// 标签：独立于备注的服务端字段，经 POST/DELETE /envs/labels 差量同步
  List<String> _labels = [];
  List<String> _originalLabels = [];

  @override
  void initState() {
    super.initState();
    if (widget.envBean != null) {
      envBean = widget.envBean!;
      _nameController.text = envBean.name ?? "";
      _valueController.text = envBean.value ?? "";
      _remarkController.text = envBean.remarks ?? "";
      _labels = List<String>.from(envBean.labels ?? <String>[]);
      _originalLabels = List<String>.from(_labels);
    } else {
      envBean = EnvBean();
    }
    // 输入框失焦（点其它任意地方）自动暂存标签，与官方交互一致
    _labelFocusNode.addListener(_onLabelFocusChanged);
  }

  @override
  void dispose() {
    _labelFocusNode.removeListener(_onLabelFocusChanged);
    _labelFocusNode.dispose();
    _nameController.dispose();
    _valueController.dispose();
    _remarkController.dispose();
    _labelInputController.dispose();
    super.dispose();
  }

  void _onLabelFocusChanged() {
    if (!_labelFocusNode.hasFocus && _addingLabel) {
      _commitLabel();
    }
  }

  void _showSplitTip() {
    showCupertinoDialog(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("是否拆分"),
        content: const Text(
          "开启后，值的每个非空行会创建为一个独立变量；"
          "关闭则整段（含换行）作为一个变量值提交。",
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

  /// 标签输入框描边：圆角 6、1px 主题蓝，四种状态统一
  OutlineInputBorder _labelInputBorder(bool dark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: (dark ? const Color(0xff69B1FF) : const Color(0xff1677FF))
            .withValues(alpha: 0.65),
      ),
    );
  }

  void _startAddLabel() {
    if (_addingLabel) {
      // 已在输入态时再点「新建」，回到输入框继续输入
      _labelFocusNode.requestFocus();
      return;
    }
    setState(() => _addingLabel = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _addingLabel) {
        _labelFocusNode.requestFocus();
      }
    });
  }

  void _commitLabel() {
    if (!_addingLabel) {
      return;
    }
    final String raw = _labelInputController.text.trim();
    _labelInputController.clear();
    setState(() {
      _addingLabel = false;
      if (raw.isNotEmpty) {
        for (final String label in _splitInput(raw)) {
          if (!_labels.contains(label)) {
            _labels.add(label);
          }
        }
      }
    });
  }

  List<String> _splitInput(String raw) {
    return raw
        .split(RegExp(r'[,，]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
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
        title: envBean.name == null ? "新增环境变量" : "编辑环境变量",
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const TitleWidget("名称", required: true),
                    const SizedBox(height: 10),
                    TextField(
                      focusNode: (envBean.sId == null || envBean.sId!.isEmpty)
                          ? focusNode
                          : null,
                      controller: _nameController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(hintText: "请输入名称"),
                      autofocus: false,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const TitleWidget("值", required: true),
                        const Spacer(),
                        // 新建时提供官方同款「是否拆分」开关（气泡说明）
                        if (envBean.id == null) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _showSplitTip,
                            child: Row(
                              children: [
                                Text(
                                  "是否拆分",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ref
                                        .watch(themeProvider)
                                        .themeColor
                                        .descColor(),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.help_outline,
                                  size: 13,
                                  color: ref
                                      .watch(themeProvider)
                                      .themeColor
                                      .descColor(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.75,
                            child: CupertinoSwitch(
                              activeTrackColor: ref
                                  .watch(themeProvider)
                                  .primaryColor,
                              value: _splitValue,
                              onChanged: (value) =>
                                  setState(() => _splitValue = value),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      focusNode: (envBean.sId == null || envBean.sId!.isEmpty)
                          ? null
                          : focusNode,
                      controller: _valueController,
                      maxLines: 8,
                      minLines: 1,
                      decoration: const InputDecoration(hintText: "请输入值"),
                      autofocus: false,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const TitleWidget("备注"),
                    const SizedBox(height: 10),
                    TextField(
                      maxLines: 3,
                      minLines: 1,
                      controller: _remarkController,
                      decoration: const InputDecoration(hintText: "请输入备注"),
                      autofocus: false,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const TitleWidget("标签"),
                    const SizedBox(height: 10),
                    // 标签编辑：芯片 +「+ 新建」+ 同排输入框（官方 Ant Tag 观感）
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (int i = 0; i < _labels.length; i++)
                          LabelTag(
                            _labels[i],
                            onRemove: () => setState(() => _labels.removeAt(i)),
                          ),
                        // 输入框在「+ 新建」之前，点击后就地展开
                        if (_addingLabel)
                          SizedBox(
                            width: 108,
                            child: TextField(
                              controller: _labelInputController,
                              focusNode: _labelFocusNode,
                              autofocus: true,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.2,
                                color: dark
                                    ? Colors.white
                                    : const Color(0xff1c1c1e),
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: dark
                                    ? const Color(0xff1677FF)
                                          .withValues(alpha: 0.10)
                                    : Colors.white,
                                hintText: "新标签",
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: ref
                                      .watch(themeProvider)
                                      .themeColor
                                      .descColor()
                                      .withValues(alpha: 0.5),
                                ),
                                // 上下内边距撑出 26px 高度，文字自然垂直居中
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                border: _labelInputBorder(dark),
                                enabledBorder: _labelInputBorder(dark),
                                focusedBorder: _labelInputBorder(dark),
                                disabledBorder: _labelInputBorder(dark),
                                errorBorder: _labelInputBorder(dark),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _commitLabel(),
                              onTapOutside: (_) => _commitLabel(),
                            ),
                          ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _startAddLabel,
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: dark
                                    ? const Color(0xff3A3A3C)
                                    : const Color(0xffD9D9D9),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 12,
                                  color: ref
                                      .watch(themeProvider)
                                      .themeColor
                                      .descColor(),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "新建",
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.0,
                                    color: ref
                                        .watch(themeProvider)
                                        .themeColor
                                        .descColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void submit() async {
    try {
      if (_nameController.text.isEmpty) {
        "名称不能为空".toast();
        return;
      }
      if (_valueController.text.isEmpty) {
        "值不能为空".toast();
        return;
      }
      hideKeyboardFocus();

      final String remarks = _remarkController.text;
      envBean.name = _nameController.text;
      envBean.value = _valueController.text;
      envBean.remarks = remarks;

      final api = SingleAccountPageState.ofApi(context);
      final bool isCreate = envBean.id == null;

      // 新增且带标签：先快照现有变量 id，创建后据此定位新变量
      //（/envs/labels 仅作用于已存在变量，创建接口无法携带标签）
      Set<int>? beforeIds;
      if (isCreate && _labels.isNotEmpty) {
        final before = await api.envs("");
        if (before.success && before.bean != null) {
          beforeIds = before.bean!
              .where((e) => e.id != null)
              .map((e) => e.id!)
              .toSet();
        }
      }

      await EasyLoading.show(status: " 提交中");
      if (!mounted) {
        return;
      }
      HttpResponse<NullResponse> response;
      if (isCreate) {
        // 新建：按开关决定整段一条，还是按换行拆分多条（官方前端同款行为）
        List<String> values = <String>[_valueController.text];
        if (_splitValue) {
          final List<String> lines = _valueController.text
              .split(RegExp(r'[\r\n]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (lines.isNotEmpty) {
            values = lines;
          }
        }
        response = values.length > 1
            ? await api.addEnvs(_nameController.text, values, remarks)
            : await api.addEnv(_nameController.text, values.first, remarks);
      } else {
        response = await api.addEnv(
          _nameController.text,
          _valueController.text,
          remarks,
          id: envBean.id,
          nId: envBean.nId,
        );
      }
      if (response.success) {
        bool labelsOk = true;
        if (isCreate) {
          // 创建后重拉列表，新出现的同名变量即为本次创建（多行值会生成多条）
          final after = await api.envs("");
          if (after.success && after.bean != null && beforeIds != null) {
            final Set<int> existingIds = beforeIds;
            final List<int> newIds = after.bean!
                .where(
                  (e) =>
                      e.id != null &&
                      !existingIds.contains(e.id) &&
                      (e.name ?? "") == _nameController.text,
                )
                .map((e) => e.id!)
                .toList();
            if (newIds.isEmpty) {
              labelsOk = false;
            } else {
              labelsOk = (await api.updateEnvLabels(newIds, _labels)).success;
            }
          } else {
            labelsOk = false;
          }
        } else {
          final List<String> added = _labels
              .where((l) => !_originalLabels.contains(l))
              .toList();
          final List<String> removed = _originalLabels
              .where((l) => !_labels.contains(l))
              .toList();
          if (added.isNotEmpty) {
            labelsOk = (await api.updateEnvLabels([
              envBean.id!,
            ], added)).success;
          }
          if (labelsOk && removed.isNotEmpty) {
            labelsOk = (await api.updateEnvLabels(
              [envBean.id!],
              removed,
              remove: true,
            )).success;
          }
        }
        await EasyLoading.dismiss();
        if (!mounted) {
          return;
        }
        if (!labelsOk) {
          "标签未能自动添加，请在编辑页重试".toast();
        }
        (envBean.sId == null || envBean.sId!.isEmpty) ? "新增成功" : "修改成功".toast();
        Navigator.of(context).pop();
      } else {
        await EasyLoading.dismiss();
        (response.message ?? "").toast();
      }
    } catch (e) {
      EasyLoading.dismiss();
    }
  }

  @override
  void onLazyLoad() {
    focusNode.requestFocus();
  }
}
