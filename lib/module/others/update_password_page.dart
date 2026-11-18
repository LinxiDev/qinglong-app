import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/commit_button.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/main.dart' show getIt;
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/module/subscribe/add_subscribe_page.dart';
import 'package:qinglong_app/utils/extension.dart';

class UpdatePasswordPage extends ConsumerStatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  ConsumerState<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends ConsumerState<UpdatePasswordPage>
    with LazyLoadState<UpdatePasswordPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordAgainController =
      TextEditingController();

  FocusNode focusNode = FocusNode();

  /// 本地选择的头像文件路径（用于预览，上传成功后“我的”页会刷新头像）
  String? _avatarPath;

  /// 面板 v2.24+ 才支持头像上传
  bool get _supportAvatarUpload {
    try {
      return getIt<SystemBean>(
        instanceName: (SingleAccountPageState.of(context)?.index ?? 0)
            .toString(),
      ).isUpperVersion2_24_0();
    } catch (e) {
      return false;
    }
  }

  /// 选择图片并上传头像
  void _pickAndUploadAvatar() async {
    if (!_supportAvatarUpload) {
      "当前面板版本过低，不支持更换头像（需要 v2.24+）".toast();
      return;
    }
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) {
      return;
    }
    final String? path = files.first.path;
    if (path == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _avatarPath = path;
    });
    EasyLoading.show(status: "上传中");
    var response = await SingleAccountPageState.ofApi(context).updateAvatar(
      path,
    );
    EasyLoading.dismiss();
    if (!mounted) {
      return;
    }
    if (response.success) {
      "头像更新成功".toast();
    } else {
      response.message.toast();
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
        title: "修改用户名密码",
      ),
      body: SingleChildScrollView(
        primary: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 头像上传区：点击选择图片，成功后“我的”页重新进入即可看到新头像
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ref
                              .watch(themeProvider)
                              .themeColor
                              .settingBgColor(),
                          border: Border.all(
                            color: ref.watch(themeProvider).primaryColor,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _avatarPath == null
                            ? Icon(
                                Icons.person,
                                size: 44,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .descColor(),
                              )
                            : Image.file(
                                File(_avatarPath!),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ref.watch(themeProvider).primaryColor,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const TitleWidget("用户名", required: true),
                  const SizedBox(height: 10),
                  TextField(
                    focusNode: focusNode,
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: "请输入用户名"),
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
                  const TitleWidget("新密码", required: true),
                  const SizedBox(height: 10),
                  TextField(
                    obscureText: true,
                    controller: _passwordController,
                    maxLines: 1,
                    decoration: const InputDecoration(hintText: "请输入新密码"),
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
                  const TitleWidget("再次输入新密码", required: true),
                  const SizedBox(height: 10),
                  TextField(
                    obscureText: true,
                    maxLines: 1,
                    controller: _passwordAgainController,
                    decoration: const InputDecoration(hintText: "再次输入新密码"),
                    autofocus: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void submit() async {
    if (_nameController.text.isEmpty) {
      "用户名不能为空".toast();
      return;
    }
    if (_passwordController.text.isEmpty ||
        _passwordAgainController.text.isEmpty) {
      "密码不能为空".toast();
      return;
    }

    if (_passwordAgainController.text != _passwordController.text) {
      "两次输入的密码不一致".toast();
      return;
    }

    commitReal();
  }

  void commitReal() async {
    String name = _nameController.text;
    String password = _passwordController.text;
    HttpResponse<NullResponse> response = await SingleAccountPageState.ofApi(
      context,
    ).updatePassword(name, password);

    if (response.success) {
      "更新成功".toast();

      if (mounted) {
        if (!SingleAccountPageState.ofUserInfo(context).useSecretLogined) {
          if (mounted) {
            SingleAccountPageState.ofUserInfo(context).updateUserName(
              SingleAccountPageState.ofUserInfo(context).host ?? "",
              name,
              password,
              false,
              SingleAccountPageState.ofUserInfo(context).alias,
            );
          }
        }
      }
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.routeLogin, (route) => false);
      }
    } else {
      response.message.toast();
    }
  }

  @override
  void onLazyLoad() {
    focusNode.requestFocus();
  }
}
