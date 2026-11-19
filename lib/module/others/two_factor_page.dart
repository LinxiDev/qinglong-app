import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/utils/extension.dart';

/// 两步验证管理（官方 /user/two-factor/*）
///
/// 启用后服务端会清空全部令牌，当前会话也会掉线，需要重新登录。
class TwoFactorPage extends ConsumerStatefulWidget {
  const TwoFactorPage({super.key});

  @override
  ConsumerState<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends ConsumerState<TwoFactorPage> {
  bool loading = true;
  bool activating = false;
  bool activated = false;
  String? secret;
  String? otpauthUrl;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final api = SingleAccountPageState.ofApi(context);
    final userResponse = await api.user();
    final bool isActivated =
        userResponse.success &&
        (userResponse.bean?.twoFactorActivated ?? false);
    if (!mounted) {
      return;
    }
    setState(() {
      activated = isActivated;
    });
    if (!isActivated) {
      final response = await api.twoFactorInit();
      if (!mounted) {
        return;
      }
      if (response.success) {
        try {
          final dynamic data = jsonDecode(response.bean ?? "{}");
          if (data is Map) {
            secret = data["secret"]?.toString();
            otpauthUrl = data["url"]?.toString();
          }
        } catch (e) {
          logger.e(e);
        }
      } else {
        (response.message ?? "获取密钥失败").toast();
      }
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> enable() async {
    final String code = _codeController.text.trim();
    if (code.length != 6) {
      "请输入 6 位动态验证码".toast();
      return;
    }
    setState(() {
      activating = true;
    });
    final response = await SingleAccountPageState.ofApi(context)
        .activeTwoFactor(code);
    if (!mounted) {
      return;
    }
    setState(() {
      activating = false;
    });
    if (response.success && response.bean == "true") {
      await _forceRelogin("两步验证已启用，请重新登录");
    } else {
      "验证码错误或密钥已失效".toast();
    }
  }

  Future<void> disable() async {
    final bool? ok = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("关闭两步验证"),
        content: const Text("关闭后所有已登录设备会下线，需要重新登录，确定继续吗？"),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消"),
            onPressed: () => Navigator.of(childContext).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("关闭"),
            onPressed: () => Navigator.of(childContext).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    EasyLoading.show(status: "关闭中");
    final response = await SingleAccountPageState.ofApi(context)
        .deactivateTwoFactor();
    EasyLoading.dismiss();
    if (!mounted) {
      return;
    }
    if (response.success) {
      await _forceRelogin("两步验证已关闭，请重新登录");
    } else {
      (response.message ?? "关闭失败").toast();
    }
  }

  Future<void> _forceRelogin(String message) async {
    message.toast();
    if (!mounted) {
      return;
    }
    final int index = SingleAccountPageState.of(context)?.index ?? 0;
    SingleAccountPageState.ofUserInfo(context).updateToken(
      index,
      SingleAccountPageState.ofUserInfo(context).host,
      "",
      false,
      SingleAccountPageState.ofUserInfo(context).alias,
    );
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.routeLogin, (route) => false);
  }

  void _copy(String? text) {
    if (text == null || text.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    "已复制".toast();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return Scaffold(
      appBar: QlAppBar(
        title: "两步验证",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : ListView(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.settingBgColor(),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: activated
                        ? [
                            Text(
                              "两步验证已启用",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeColor.titleColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "登录面板时需要输入验证器 App 中的 6 位动态验证码。",
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: themeColor.descColor(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton(
                              color: const Color(0xffEA4D3E),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: disable,
                              child: const Text(
                                "关闭两步验证",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ]
                        : [
                            Text(
                              "1. 在验证器 App（如 Google Authenticator）中添加以下密钥：",
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: themeColor.titleColor(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .bg2Color(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    secret ?? "加载中…",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: themeColor.titleColor(),
                                    ),
                                  ),
                                  if (otpauthUrl != null &&
                                      otpauthUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      otpauthUrl!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: themeColor.descColor(),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _copy(secret),
                                    child: Text(
                                      "复制密钥",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ref
                                            .watch(themeProvider)
                                            .primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "2. 输入验证器生成的 6 位验证码完成启用：",
                              style: TextStyle(
                                fontSize: 13,
                                color: themeColor.titleColor(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                hintText: "6 位动态验证码",
                                counterText: "",
                              ),
                            ),
                            const SizedBox(height: 12),
                            CupertinoButton(
                              color: ref.watch(themeProvider).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              onPressed: activating ? null : enable,
                              child: Text(
                                activating ? "启用中…" : "启用两步验证",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                  ),
                ),
              ],
            ),
    );
  }
}
