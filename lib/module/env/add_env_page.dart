import 'package:material_ui/material_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/commit_button.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
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
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.envBean != null) {
      envBean = widget.envBean!;
      _nameController.text = envBean.name ?? "";
      _valueController.text = envBean.value ?? "";
      _remarkController.text = envBean.remarks ?? "";
    } else {
      envBean = EnvBean();
    }
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
                    const TitleWidget("值", required: true),
                    const SizedBox(height: 10),
                    TextField(
                      focusNode: (envBean.sId == null || envBean.sId!.isEmpty)
                          ? null
                          : focusNode,
                      controller: _valueController,
                      maxLines: 8,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: "请输入值（支持多行，换行即多个值）",
                      ),
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

      envBean.name = _nameController.text;
      envBean.value = _valueController.text;
      envBean.remarks = _remarkController.text;

      await EasyLoading.show(status: " 提交中");
      if (!mounted) {
        return;
      }
      HttpResponse<NullResponse> response =
          await SingleAccountPageState.ofApi(context).addEnv(
            _nameController.text,
            _valueController.text,
            _remarkController.text,
            id: envBean.id,
            nId: envBean.nId,
          );
      await EasyLoading.show(status: " 提交中");
      if (envBean.sId != null && envBean.sId!.isNotEmpty) {
        if (mounted) {
          await SingleAccountPageState.ofApi(context).enableEnv([envBean.sId!]);
        }
      }
      await EasyLoading.dismiss();
      if (response.success) {
        (envBean.sId == null || envBean.sId!.isEmpty)
            ? "新增成功"
            : "修改成功${envBean.status == 1 ? ",并自动启用" : ""}".toast();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
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
