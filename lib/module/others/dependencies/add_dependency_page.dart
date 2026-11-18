import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/commit_button.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/module/others/dependencies/dependency_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';

class AddDependencyPage extends ConsumerStatefulWidget {
  const AddDependencyPage({
    super.key,
  });

  @override
  ConsumerState<AddDependencyPage> createState() => _AddDependencyPageState();
}

class _AddDependencyPageState extends ConsumerState<AddDependencyPage> {
  final TextEditingController _nameController = TextEditingController();

  DepedencyEnum depedencyType = DepedencyEnum.nodeJs;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        title: "新增依赖",
        actions: [
          CommitButton(
            onTap: () {
              submit();
            },
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "依赖类型",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<DepedencyEnum>(
                  items: [
                    DropdownMenuItem(
                      value: DepedencyEnum.nodeJs,
                      child: Text(DepedencyEnum.nodeJs.name),
                    ),
                    DropdownMenuItem(
                      value: DepedencyEnum.python3,
                      child: Text(DepedencyEnum.python3.name),
                    ),
                    DropdownMenuItem(
                      value: DepedencyEnum.linux,
                      child: Text(DepedencyEnum.linux.name),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 14,
                    color: ref.watch(themeProvider).themeColor.title2Color(),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.chevron_up_chevron_down,
                    size: 16,
                  ),
                  initialValue: DepedencyEnum.nodeJs,
                  onChanged: (value) {
                    depedencyType = value!;
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "名称",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _nameController,
                  maxLines: 10,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: "请输入名称,多个依赖换行添加",
                  ),
                  autofocus: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void submit() async {
    try {
      if (_nameController.text.isEmpty) {
        "依赖名称不能为空".toast();
        return;
      }

      List<Map<String, dynamic>> list = [];

      List<String> names = _nameController.text.split("\n");
      list.addAll(names
          .map(
            (e) => {
              "name": e,
              "type": depedencyType.index,
            },
          )
          .toList());
      await EasyLoading.show(status: " 提交中");
      // ignore: use_build_context_synchronously
      HttpResponse<String> response = await SingleAccountPageState.ofApi(context).addDependency(list);

      await EasyLoading.dismiss();
      if (response.success) {
        Map<String, dynamic> data = {};

        if (response.bean != null) {
          var list = jsonDecode(response.bean!) as List<dynamic>;
          if (list.isNotEmpty && list.length == 1) {
            data = (list[0] as Map<String, dynamic>);
          } else {
            "新增成功".toast();
          }
        }
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(data);
      } else {
        response.message.toast();
      }
    } catch (e) {
      EasyLoading.dismiss();
    }
  }
}
