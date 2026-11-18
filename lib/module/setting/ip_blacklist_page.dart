import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../main.dart';

/// IP 黑名单（青龙 v2.22+）
///
/// 被加入黑名单的 IP 无法登录面板，可用于应急阻断异常来源。
class IpBlacklistPage extends ConsumerStatefulWidget {
  const IpBlacklistPage({super.key});

  @override
  ConsumerState<IpBlacklistPage> createState() => _IpBlacklistPageState();
}

class _IpBlacklistPageState extends ConsumerState<IpBlacklistPage> {
  bool loading = true;
  bool operating = false;
  List<String> ips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    final HttpResponse<String> response = await SingleAccountPageState.ofApi(
      context,
    ).getIpBlacklist();

    if (!mounted) {
      return;
    }

    if (response.success) {
      try {
        final dynamic data = jsonDecode(response.bean ?? "[]");
        if (data is List) {
          ips = data.map((e) => "$e").toList();
        }
      } catch (e) {
        logger.e(e);
      }
    } else {
      response.message.toast();
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> addIp() async {
    final Color primary = ref.read(themeProvider).primaryColor;
    final api = SingleAccountPageState.ofApi(context);
    final TextEditingController controller = TextEditingController();
    final String? ip = await showCupertinoDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (childContext) => CupertinoAlertDialog(
        title: const Text("添加 IP 黑名单"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(hintText: "例如 1.2.3.4"),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("取消", style: TextStyle(color: Color(0xff999999))),
            onPressed: () => Navigator.of(childContext).pop(),
          ),
          CupertinoDialogAction(
            child: Text("确定", style: TextStyle(color: primary)),
            onPressed: () =>
                Navigator.of(childContext).pop(controller.text.trim()),
          ),
        ],
      ),
    );

    if (ip == null || ip.isEmpty) return;

    setState(() {
      operating = true;
    });

    final response = await api.addIpBlacklist(ip);

    if (!mounted) {
      return;
    }

    setState(() {
      operating = false;
    });

    if (response.success) {
      "已加入黑名单".toast();
      loadData();
    } else {
      (response.message ?? "添加失败").toast();
    }
  }

  Future<void> removeIp(String ip) async {
    EasyLoading.show(status: "处理中");
    final response = await SingleAccountPageState.ofApi(context)
        .deleteIpBlacklist(ip);
    EasyLoading.dismiss();

    if (!mounted) {
      return;
    }

    if (response.success) {
      "已移出黑名单".toast();
      loadData();
    } else {
      (response.message ?? "移除失败").toast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(themeProvider).themeColor.bg2Color(),
      appBar: QlAppBar(
        title: "IP 黑名单",
        canBack: true,
        backCall: () => Navigator.of(context).pop(),
        actions: [
          operating
              ? const SizedBox.shrink()
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: addIp,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Center(child: Icon(CupertinoIcons.add, size: 22)),
                  ),
                ),
        ],
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              color: ref.watch(themeProvider).primaryColor,
              onRefresh: loadData,
              child: ips.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Center(
                          child: Text(
                            "暂无黑名单\n点击右上角 + 添加需要阻断的 IP",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: ref
                                  .watch(themeProvider)
                                  .themeColor
                                  .descColor(),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 30),
                      itemCount: ips.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: ref
                                .watch(themeProvider)
                                .themeColor
                                .settingBordorColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              CupertinoIcons.nosign,
                              size: 20,
                              color: ref
                                  .watch(themeProvider)
                                  .themeColor
                                  .hintColor(),
                            ),
                            title: Text(
                              ips[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: ref
                                    .watch(themeProvider)
                                    .themeColor
                                    .titleColor(),
                              ),
                            ),
                            trailing: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () => removeIp(ips[index]),
                              child: Text(
                                "解除",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ref.watch(themeProvider).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
