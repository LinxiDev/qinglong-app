import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../../base/commit_button.dart';

class InTimeSubscribeLogPage extends StatefulWidget {
  final int cronId;
  final bool needTimer;
  final String title;

  const InTimeSubscribeLogPage(
    this.cronId,
    this.needTimer,
    this.title, {
    super.key,
  });

  @override
  InTimeSubscribeLogPageState createState() => InTimeSubscribeLogPageState();
}

class InTimeSubscribeLogPageState extends State<InTimeSubscribeLogPage>
    with LazyLoadState<InTimeSubscribeLogPage> {
  Timer? _timer;

  String? content;

  ScrollController? controller = ScrollController();

  @override
  void initState() {
    super.initState();
    getLogData();
  }

  bool alwaysAuthScroll = false;

  bool isRequest = false;
  bool canRequest = true;

  Future<void> getLogData() async {
    if (!canRequest) return;
    if (isRequest) return;
    isRequest = true;
    HttpResponse<String> response = await SingleAccountPageState.ofApi(context)
        .inTimeSubscribeLog(widget.cronId);
    if (response.success) {
      content = response.bean;
      if (alwaysAuthScroll) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if ((controller?.hasClients ?? false)) {
            controller!.jumpTo(controller!.position.maxScrollExtent);
          }
        });
      }
      setState(() {});
    }
    isRequest = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            mini: true,
            // 主题覆盖后 FAB 默认配色对比度过低，显式指定主色底+白图标
            backgroundColor: const Color(0xFF20b54f),
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() {
                alwaysAuthScroll = !alwaysAuthScroll;
              });
            },
            elevation: 2,
            child: Icon(
              alwaysAuthScroll
                  ? CupertinoIcons.pause_circle
                  : CupertinoIcons.play_circle,
            ),
          ),
          appBar: QlAppBar(
            canBack: true,
            actions: [
              CommitButton(
                title: "分享",
                onTap: () {
                  SharePlus.instance.share(ShareParams(text: content ?? ""));
                },
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
                        controller: controller,
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
      },
    );
  }

  @override
  void onLazyLoad() {
    alwaysAuthScroll = SpUtil.getBool(spLogAutoJump2Bottom, defValue: true);
    if (widget.needTimer) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        getLogData();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        getLogData();
      });
    }
  }
}
