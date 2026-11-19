import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../../base/cupertino_sheet.dart';
import '../../../main.dart';
import '../../home/system_bean.dart';

class InTimeHistoryLogPage extends StatefulWidget {
  final String title;
  final String path;

  const InTimeHistoryLogPage({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  InTimeHistoryLogPageState createState() => InTimeHistoryLogPageState();
}

class InTimeHistoryLogPageState extends State<InTimeHistoryLogPage>
    with LazyLoadState<InTimeHistoryLogPage> {
  String? content;

  bool isRequest = false;
  bool canRequest = true;

  Future<void> getLogData() async {
    HttpResponse<String> response = await SingleAccountPageState.ofApi(context)
        .taskLogDetail(widget.title, widget.path);

    if (response.success) {
      content = response.bean;
      setState(() {});
    } else {
      (response.message ?? "").toast();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        canBack: true,
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: () {
              showMoreOperate(context, [
                CupertinoSheer(
                  title: "分享",
                  icon: CupertinoIcons.share,
                  onTap: () async {
                    SharePlus.instance.share(ShareParams(text: content ?? ""));
                  },
                ),
                addDivider(),
                CupertinoSheer(
                  title: "下载",
                  icon: CupertinoIcons.cloud_download,
                  onTap: () async {
                    EasyLoading.show(status: "下载中");
                    final response = await SingleAccountPageState.ofApi(context)
                        .downloadLog(widget.title, widget.path);
                    EasyLoading.dismiss();
                    if (!context.mounted) {
                      return;
                    }
                    if (response.success) {
                      final String name =
                          "${DateTime.now().millisecondsSinceEpoch}_"
                          "${widget.title.split("/").last}";
                      await FileUtil(0)
                          .writeDownloadFile(name, response.bean ?? "");
                      "已写入qinglong_app文件夹下,文件名$name".toast2();
                    } else {
                      (response.message ?? "下载失败").toast();
                    }
                  },
                ),
                addDivider(),
                CupertinoSheer(
                  title: "删除",
                  icon: CupertinoIcons.delete,
                  destructive: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    deleteFold(widget.title, widget.path);
                  },
                ),
              ]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  size: 26,
                  color: Theme.of(context).appBarTheme.iconTheme?.color,
                ),
              ),
            ),
          ),
        ],
        title: widget.title,
      ),
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 10),
          child: (content == null)
              ? const Center(child: LoadingWidget())
              : CupertinoScrollbar(
                  child: SingleChildScrollView(
                    primary: true,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SelectableText(
                      content!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void onLazyLoad() {
    getLogData();
  }

  void deleteFold(String title, String path) async {
    SystemBean? systemBean;

    try {
      systemBean = getIt<SystemBean>(
        instanceName: (SingleAccountPageState.of(context)?.index ?? 0)
            .toString(),
      );
    } catch (e) {
      systemBean = SystemBean(version: "2.10.13", fromAutoGet: false);
    }
    if (!systemBean.isUpperVersion2_14_5()) {
      "该功能仅支持v2.14.5及以上版本".toast();
      return;
    }

    EasyLoading.show(status: "删除中...");
    var temp = await SingleAccountPageState.ofApi(context)
        .deleteLog(title, path);
    EasyLoading.dismiss();
    if (temp.success) {
      "已删除".toast();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      temp.message.toast();
    }
  }
}
