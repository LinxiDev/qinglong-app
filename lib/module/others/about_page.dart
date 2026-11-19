import 'dart:convert';
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/app_logo.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/module/setting/panel_upgrade_page.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/module/in_app_purchase_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';

const String kRepoUrl = "https://github.com/LinxiDev/qinglong-app";
const String kGithubApiLatest =
    "https://api.github.com/repos/LinxiDev/qinglong-app/releases/latest";
const String kReleaseUrl = "$kRepoUrl/releases";
const String kWikiUrl = "$kRepoUrl/wiki";
const String kAuthor = "林夕";

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage>
    with LazyLoadState<AboutPage> {
  String desc = "";
  String versionCode = "";

  /// GitHub 最新 Release 的版本号（如 4.0.1）
  String? latestVersion;

  @override
  void initState() {
    super.initState();
    getInfo();
    checkGithubRelease();
  }

  @override
  Widget build(BuildContext context) {
    SystemBean systemBean;

    try {
      systemBean = getIt<SystemBean>(
        instanceName: (SingleAccountPageState.of(context)?.index ?? 0)
            .toString(),
      );
    } catch (e) {
      systemBean = SystemBean(version: "2.10.13", fromAutoGet: false);
    }
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(canBack: true, title: "关于软件"),
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 25),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const AppLogo(height: 60),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "青龙客户端",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ref.watch(themeProvider).themeColor.titleColor(),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  "基于青龙开源项目打造的第三方${getPlatformName()}客户端",
                  style: TextStyle(
                    color: ref.watch(themeProvider).themeColor.descColor(),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoCard(systemBean),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "功能与链接",
                  style: TextStyle(
                    color: ref.watch(themeProvider).themeColor.descColor(),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildLinkCard(),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  "APP不会收集任何关于您的信息,使用前请仔细阅读用户协议",
                  style: TextStyle(
                    color: ref.watch(themeProvider).themeColor.descColor(),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(SystemBean systemBean) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
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
        children: [
          _buildRow(
            label: "版本",
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$desc ($versionCode)",
                  style: TextStyle(
                    color: ref.watch(themeProvider).themeColor.descColor(),
                    fontSize: 15,
                  ),
                ),
                if (latestVersion != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openReleases,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4D3E),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        "有新版本 v$latestVersion",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _divider(),
          _buildRow(
            label: "作者",
            valueWidget: Text(
              kAuthor,
              style: TextStyle(
                color: ref.watch(themeProvider).themeColor.descColor(),
                fontSize: 15,
              ),
            ),
          ),
          _divider(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _checkUpdate,
              child: _buildRow(
                label: "青龙服务端",
                valueWidget: Text(
                  "${systemBean.version}",
                  style: TextStyle(
                    color: ref.watch(themeProvider).themeColor.descColor(),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
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
        children: [
          _buildLinkRow(
            icon: CupertinoIcons.cloud_download,
            label: "下载地址",
            onTap: _openReleases,
          ),
          _divider(indent: 50),
          _buildLinkRow(
            icon: CupertinoIcons.doc_text,
            label: "功能介绍",
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) =>
                      const InAppPurchasePage(fromDirectly: true),
                ),
              );
            },
          ),
          _divider(indent: 50),
          _buildLinkRow(
            icon: CupertinoIcons.book,
            label: "用户协议",
            onTap: () => _launchURL(kWikiUrl),
          ),
          _divider(indent: 50),
          _buildLinkRow(
            icon: CupertinoIcons.paperplane,
            label: "APP更新通知",
            onTap: () => _launchURL(kWikiUrl),
          ),
          _divider(indent: 50),
          if (Platform.isIOS) ...[
            _buildLinkRow(
              icon: CupertinoIcons.heart,
              label: "在 App Store 评分",
              onTap: () {
                InAppReview.instance.openStoreListing(appStoreId: "1625871665");
              },
            ),
            _divider(indent: 50),
          ],
          _buildLinkRow(
            icon: CupertinoIcons.share,
            label: "分享App",
            onTap: () {
              const String shareText = "分享一款好用的青龙客户端，下载地址：$kReleaseUrl";
              SharePlus.instance.share(ShareParams(text: shareText));
            },
          ),
        ],
      ),
    );
  }

  Widget _divider({double indent = 18}) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: indent,
      endIndent: indent,
      color: dark ? const Color(0xFF2E2E31) : const Color(0xFFECEEF1),
    );
  }

  Widget _buildRow({required String label, required Widget valueWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: ref.watch(themeProvider).themeColor.titleColor(),
              fontSize: 15.5,
            ),
          ),
          const Spacer(),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildLinkRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          child: Row(
            children: [
              Icon(
                icon,
                color: ref.watch(themeProvider).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 15),
              Text(
                label,
                style: TextStyle(
                  color: ref.watch(themeProvider).themeColor.titleColor(),
                  fontSize: 15.5,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.right_chevron,
                size: 16,
                color: ref.watch(themeProvider).themeColor.descColor(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReleases() {
    _launchURL(kReleaseUrl);
  }

  void _launchURL(String url) async {
    try {
      await launchUrl(Uri.tryParse(url.trimLeft())!);
    } catch (e) {
      logger.e(e);
    }
  }

  void getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;
    versionCode = packageInfo.buildNumber;
    desc = version;
    if (mounted) {
      setState(() {});
    }
  }

  /// 通过 GitHub API 检测 App 新版本
  Future<void> checkGithubRelease() async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(
        Uri.parse(kGithubApiLatest),
      );
      request.headers.set("User-Agent", "qinglong-app");
      request.headers.set("Accept", "application/vnd.github+json");
      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) {
        return;
      }
      final String body = await response.transform(utf8.decoder).join();
      final dynamic data = jsonDecode(body);
      final String tag = (data["tag_name"] ?? "").toString();
      if (tag.isEmpty) {
        return;
      }
      final String normalized = tag.replaceFirst(RegExp(r'^[vV]'), "");
      // 仅当 Release 版本严格大于当前版本时才提示新版本（相等或更低不算）
      if (mounted && desc.isNotEmpty && _isVersionGreater(normalized, desc)) {
        setState(() {
          latestVersion = normalized;
        });
      }
    } catch (e) {
      // 网络异常时静默忽略，不打扰用户
      logger.i("检查 APP 更新失败: $e");
    }
  }

  @override
  void onLazyLoad() {}

  /// 点击「青龙服务端」：有版本检测结果后分流——
  /// 有新版本 → 进入面板升级页（可下载/应用/重启）；无新版本 → 仅提示
  /// 点击「青龙服务端」：有新版本弹窗引导去升级，无新版本仅提示
  void _checkUpdate() async {
    var response = await SingleAccountPageState.ofApi(context).checkUpdate();
    if (!mounted) {
      return;
    }
    if (response.success) {
      if (response.bean?.hasNewVersion ?? false) {
        showCupertinoDialog(
          context: context,
          useRootNavigator: false,
          builder: (childContext) => CupertinoAlertDialog(
            title: Text("青龙服务端发现新版本 ${response.bean?.lastVersion}"),
            content: Padding(
              padding: const EdgeInsets.only(left: 5, top: 5),
              child: Text(
                "${response.bean?.lastLog}",
                textAlign: TextAlign.left,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.of(childContext).pop();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text("去升级"),
                onPressed: () {
                  Navigator.of(childContext).pop();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const PanelUpgradePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        "已是最新版本".toast();
      }
    } else {
      response.message?.toast();
    }
  }
}

/// 语义化版本号比较：a > b 返回 true（按数字段逐段比较，如 1.2.10 > 1.2.9）
bool _isVersionGreater(String a, String b) {
  final List<String> pa = a.split('.');
  final List<String> pb = b.split('.');
  final int len = pa.length > pb.length ? pa.length : pb.length;
  for (int i = 0; i < len; i++) {
    final int va = i < pa.length ? (int.tryParse(pa[i]) ?? 0) : 0;
    final int vb = i < pb.length ? (int.tryParse(pb[i]) ?? 0) : 0;
    if (va != vb) {
      return va > vb;
    }
  }
  return false;
}

String getPlatformName() {
  if (Platform.isAndroid) {
    return "Android";
  }
  return "iOS";
}
