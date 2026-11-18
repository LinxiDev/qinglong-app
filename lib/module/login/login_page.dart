import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/app_logo.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/base/ui/shake.dart';
import 'package:qinglong_app/utils/idn.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/in_app_purchase_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/login_helper.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:qinglong_app/utils/utils.dart';
import 'package:flip_card/flip_card.dart';

import '../others/change_account_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool fromAddNewAccount;

  const LoginPage({super.key, this.fromAddNewAccount = false});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cIdController = TextEditingController();
  final TextEditingController _cSecretController = TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  bool rememberPassword = false;

  @override
  void initState() {
    super.initState();
    if (!widget.fromAddNewAccount) {
      _hostController.text =
          SingleAccountPageState.ofUserInfo(context).host ?? "";
      if (SingleAccountPageState.ofUserInfo(context).userName != null &&
          SingleAccountPageState.ofUserInfo(context).userName!.isNotEmpty) {
        if (SingleAccountPageState.ofUserInfo(context).useSecretLogined) {
          _cIdController.text = SingleAccountPageState.ofUserInfo(context)
              .userName!;
        } else {
          _userNameController.text = SingleAccountPageState.ofUserInfo(context)
              .userName!;
        }
        rememberPassword = true;
      } else {
        rememberPassword = false;
      }
      if (SingleAccountPageState.ofUserInfo(context).passWord != null &&
          SingleAccountPageState.ofUserInfo(context).passWord!.isNotEmpty) {
        if (SingleAccountPageState.ofUserInfo(context).useSecretLogined) {
          _cSecretController.text = SingleAccountPageState.ofUserInfo(context)
              .passWord!;
        } else {
          _passwordController.text = SingleAccountPageState.ofUserInfo(context)
              .passWord!;
        }
      }

      if (SingleAccountPageState.ofUserInfo(context).alias != null &&
          SingleAccountPageState.ofUserInfo(context).alias!.isNotEmpty) {
        _aliasController.text = SingleAccountPageState.ofUserInfo(context)
            .alias!;
      }
    }
  }

  GlobalKey<ShakeWidgetState> loginKey = GlobalKey<ShakeWidgetState>();

  @override
  Widget build(BuildContext context) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color primary = ref.watch(themeProvider).primaryColor;
    // 大屏（桌面/平板）把表单列限制在 420 宽并居中，手机端保持 24 边距
    final double screenWidth = MediaQuery.of(context).size.width;
    final double hPad = screenWidth > 480 ? (screenWidth - 420) / 2 : 24;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            // 顶部主色微光的柔和渐变背景
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? const [Color(0xFF15241A), Color(0xFF111111)]
                  : const [Color(0xFFEAF8EE), Color(0xFFF7F9FA)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              primary: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 顶部返回（单实例模式）
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Visibility(
                        visible: SpUtil.getBool(
                          spSingleInstance,
                          defValue: false,
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.only(left: 8),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            CupertinoIcons.chevron_back,
                            color: primary,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Logo + 标题（点击切换账号/VIP，长按提示品牌）
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (SpUtil.getInt(spVIP, defValue: typeNormal) ==
                          typeNormal) {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const InAppPurchasePage(fromDirectly: true),
                          ),
                        );
                        return;
                      } else {
                        if (SpUtil.getBool(spSingleInstance, defValue: false)) {
                          Navigator.pop(context);
                          return;
                        }
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) =>
                                const ChangeAccountPage(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            "青龙客户端".toast();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(
                                    alpha: dark ? 0.15 : 0.22,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: const AppLogo(height: 72),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "账号登录",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: themeColor.title2Color(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "登录你的青龙面板，随时管理定时任务",
                          style: TextStyle(
                            fontSize: 13,
                            color: themeColor.descColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 表单卡片：图标输入行 + 细分隔线
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: hPad),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.settingBgColor(),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF2E2E31)
                            : const Color(0xFFE6E8EC),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dark
                              ? const Color(0x33000000)
                              : const Color(0x0F000000),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          icon: CupertinoIcons.globe,
                          hint: "面板地址，如 http://1.1.1.1:5700",
                          controller: _hostController,
                        ),
                        _fieldDivider(dark),
                        _buildField(
                          icon: CupertinoIcons.person,
                          hint: "请输入账户",
                          controller: _userNameController,
                        ),
                        _fieldDivider(dark),
                        _buildField(
                          icon: CupertinoIcons.lock,
                          hint: "请输入密码",
                          controller: _passwordController,
                          obscure: true,
                        ),
                        _fieldDivider(dark),
                        _buildField(
                          icon: CupertinoIcons.tag,
                          hint: "别名（选填，仅用于展示）",
                          controller: _aliasController,
                          formatters: [LengthLimitingTextInputFormatter(10)],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 记住密码
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: rememberPassword,
                            // 选中态用淡绿底 + 主题色对勾，比实心主色更柔和
                            activeColor: primary.withValues(alpha: 0.18),
                            checkColor: primary,
                            hoverColor: Colors.transparent,
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            // 未选中描边用浅灰（比文字色更淡），避免框线显得过重
                            side: BorderSide(
                              color: dark
                                  ? const Color(0xFF4A4D52)
                                  : const Color(0xFFC9CDD4),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (checked) {
                              rememberPassword = checked ?? false;
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            rememberPassword = !rememberPassword;
                            setState(() {});
                          },
                          child: Text(
                            "记住密码",
                            style: TextStyle(
                              fontSize: 13,
                              color: themeColor.descColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 登录按钮
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: ShakeWidget(
                      key: loginKey,
                      child: IgnorePointer(
                        ignoring: !canClickLoginBtn(),
                        child: GestureDetector(
                          onTap: () async {
                            if (!_hostController.text.startsWith("http://") &&
                                !_hostController.text.startsWith("https://")) {
                              "域名必须以http://或者https://开头".toast();
                              return;
                            }
                            // 中文等非 ASCII 域名转成 punycode，否则无法解析
                            final String normalizedHost = normalizeUrlHost(
                              _hostController.text,
                            );
                            if (normalizedHost != _hostController.text) {
                              _hostController.text = normalizedHost;
                            }
                            SingleAccountPageState.of(context)
                                ?.registerHttp(normalizedHost);
                            SingleAccountPageState.ofHttp(context)
                                    ?.pushedLoginPage =
                                false;
                            Utils.hideKeyBoard(context);
                            if (loginByUserName()) {
                              login(
                                _userNameController.text,
                                _passwordController.text,
                              );
                            } else {
                              login(
                                _cIdController.text,
                                _cSecretController.text,
                              );
                            }
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              // 纯色主绿替代渐变：各渲染环境表现一致，更稳定
                              color: const Color(
                                0xff0FA85A,
                              ).withValues(alpha: canClickLoginBtn() ? 1 : 0.5),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: canClickLoginBtn()
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xff089556)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isLoading
                                ? const LoadingWidget(color: Colors.white)
                                : const Text(
                                    "登 录",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 历史账号
                  (getIt<MultiAccountUserInfoViewModel>()
                          .historyAccounts
                          .isEmpty)
                      ? const SizedBox(height: 24)
                      : Center(
                          child: Material(
                            color: Colors.transparent,
                            child: PopupMenuButton<UserInfoBean>(
                              onSelected: (UserInfoBean result) {
                                selected(result);
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<UserInfoBean>>[
                                    ...getIt<MultiAccountUserInfoViewModel>()
                                        .historyAccounts
                                        .map(
                                          (e) => PopupMenuItem<UserInfoBean>(
                                            value: e,
                                            child: buildCell(context, e),
                                          ),
                                        ),
                                  ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/images/icon_history.png",
                                      fit: BoxFit.cover,
                                      width: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "历史账号",
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 登录表单的单个输入行：图标 + 无边框输入框
  Widget _buildField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    List<TextInputFormatter>? formatters,
  }) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 12),
          child: Icon(icon, size: 19, color: themeColor.descColor()),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            inputFormatters: formatters,
            onChanged: (_) {
              setState(() {});
            },
            style: TextStyle(fontSize: 15, color: themeColor.titleColor()),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: themeColor.hintColor()),
            ),
            autofocus: false,
          ),
        ),
      ],
    );
  }

  /// 表单行之间的细分隔线
  Widget _fieldDivider(bool dark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 39,
      endIndent: 8,
      color: dark ? const Color(0xFF2E2E31) : const Color(0xFFECEEF1),
    );
  }

  bool isLoading = false;

  bool loginByUserName() {
    return true;
  }

  LoginHelper? helper;

  Future<void> login(String userName, String password) async {
    isLoading = true;
    setState(() {});

    helper = LoginHelper(
      _hostController.text,
      userName,
      password,
      rememberPassword,
      _aliasController.text,
    );
    var response = await helper!.login(context);
    dealLoginResponse(response);
  }

  void dealLoginResponse(int response) {
    if (response == LoginHelper.success) {
      Navigator.of(context).pushReplacementNamed(Routes.routeHomePage);
    } else if (response == LoginHelper.failed) {
      loginFailed();
    } else {
      twoFact();
    }
  }

  void loginFailed() {
    isLoading = false;
    loginKey.currentState?.forward();
    setState(() {});
  }

  bool canClickLoginBtn() {
    if (isLoading) return false;

    if (_hostController.text.isEmpty) return false;
    if (!loginByUserName()) {
      return _cIdController.text.isNotEmpty &&
          _cSecretController.text.isNotEmpty;
    } else {
      return _userNameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    }
  }

  void twoFact() {
    String twoFact = "";
    showCupertinoDialog(
      useRootNavigator: false,
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("两步验证"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: TextField(
                onChanged: (value) {
                  twoFact = value;
                },
                maxLines: 1,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                  hintText: "请输入code",
                ),
                autofocus: true,
              ),
            ),
          ],
        ),
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
              Navigator.of(context).pop(true);
              if (helper != null) {
                var response = await helper!.loginTwice(context, twoFact);
                dealLoginResponse(response);
              } else {
                "状态异常，请重新点登录按钮".toast();
              }
            },
          ),
        ],
      ),
    ).then((value) {
      if (value == null) {
        isLoading = false;
        setState(() {});
      }
    });
  }

  Widget buildCell(BuildContext context, UserInfoBean bean) {
    return ListTile(
      title: Text(
        bean.host ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text(
          (bean.alias == null || bean.alias!.isEmpty)
              ? (bean.userName ?? "")
              : bean.alias!,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      trailing: GestureDetector(
        onTap: () {
          getIt<MultiAccountUserInfoViewModel>().removeHistoryAccount(
            bean.host,
          );
          Navigator.pop(context);

          setState(() {});
        },
        child: const Icon(CupertinoIcons.clear_thick, size: 20),
      ),
    );
  }

  void selected(UserInfoBean result) {
    _hostController.text = result.host ?? "";
    if (result.useSecretLogined) {
      _cIdController.text = result.userName ?? "";
      _cSecretController.text = result.password ?? "";
      if (cardKey.currentState?.isFront ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          cardKey.currentState?.toggleCard();
        });
      }
    } else {
      _userNameController.text = result.userName ?? "";
      _passwordController.text = result.password ?? "";
      if (!(cardKey.currentState?.isFront ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          cardKey.currentState?.toggleCard();
        });
      }
    }
    _aliasController.text = result.alias ?? "";
    rememberPassword = true;
    setState(() {});
  }
}
