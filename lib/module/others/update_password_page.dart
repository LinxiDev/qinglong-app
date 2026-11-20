import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/avatar_revision.dart';
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

  /// 本地选择的头像文件路径（上传期间预览）
  String? _avatarPath;

  /// 服务端已有头像的完整地址
  String? _avatarUrl;

  /// 选中并上传头像后回读服务端头像；返回是否成功拿到最新地址
  Future<bool> _loadAvatar() async {
    try {
      final response = await SingleAccountPageState.ofApi(context).user();
      if (!mounted || !response.success || response.bean == null) {
        return false;
      }
      final String? avatar = response.bean!.avatar;
      String? url;
      if (avatar != null && avatar.isNotEmpty) {
        if (avatar.startsWith("http")) {
          url = avatar;
        } else {
          String host = SingleAccountPageState.ofUserInfo(context).host ?? "";
          if (host.endsWith("/")) {
            host = host.substring(0, host.length - 1);
          }
          url = "$host/api/static/$avatar";
        }
      }
      setState(() {
        _avatarUrl = url;
      });
      return true;
    } catch (_) {
      // 头像加载失败保持占位 logo，不打断页面
      return false;
    }
  }

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
    if (await File(path).length() > 5 * 1024 * 1024) {
      "头像不能超过 5MB".toast();
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _avatarPath = path;
    });
    EasyLoading.show(status: "上传中");
    var response = await SingleAccountPageState.ofApi(context)
        .updateAvatar(path);
    EasyLoading.dismiss();
    if (!mounted) {
      return;
    }
    if (response.success) {
      // 重新拉取服务端头像（文件名每次上传都会变化）
      final bool loaded = await _loadAvatar();
      if (!mounted) {
        return;
      }
      if (loaded) {
        setState(() {
          _avatarPath = null;
        });
      }
      // 回读失败时保留本地预览，避免上传成功却退回旧头像
      avatarRevision.value++;
      "头像更新成功".toast();
    } else {
      // 失败撤回本地预览，回到原头像/logo
      setState(() {
        _avatarPath = null;
      });
      response.message.toast();
    }
  }

  /// 与「我的」页一致：默认显示青龙 logo
  Widget _defaultAvatar() {
    return Image.asset(
      ref.watch(themeProvider).themeMode == modeDark
          ? "assets/images/ql_dark.png"
          : "assets/images/ql.png",
      width: 60,
      height: 60,
      fit: BoxFit.cover,
    );
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
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _avatarPath != null
                              ? Image.file(
                                  File(_avatarPath!),
                                  fit: BoxFit.cover,
                                )
                              : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _avatarUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => _defaultAvatar(),
                                        errorWidget: (_, _, _) =>
                                            _defaultAvatar(),
                                      )
                                    : _defaultAvatar()),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ref.watch(themeProvider).primaryColor,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 12,
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
    _loadAvatar();
  }
}
