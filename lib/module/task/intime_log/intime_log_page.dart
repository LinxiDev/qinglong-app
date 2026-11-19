import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/module/scan_page.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../../base/commit_button.dart';
import '../../../base/http/api.dart';

class InTimeLogPage extends ConsumerStatefulWidget {
  final String cronId;
  final bool needTimer;
  final String title;
  final String? command;

  const InTimeLogPage(
    this.cronId,
    this.needTimer,
    this.title, {
    super.key,
    this.command,
  });

  @override
  InTimeLogPageState createState() => InTimeLogPageState();
}

class InTimeLogPageState extends ConsumerState<InTimeLogPage>
    with LazyLoadState<InTimeLogPage> {
  Timer? _timer;

  String? content;

  /// 已读取的日志字节偏移（官方分块接口）
  int _offset = 0;

  bool isRequest = false;
  bool canRequest = true;
  bool alwaysAuthScroll = false;

  ScrollController? controller = ScrollController();
  bool showVIPReminder = false;

  Future<void> getLogData() async {
    if (!canRequest) return;
    if (isRequest) return;
    if (!mounted) {
      return;
    }
    isRequest = true;
    final api = SingleAccountPageState.ofApi(context);
    HttpResponse<String> response;

    /// 优先使用官方分块接口：首屏取尾部 128KB，之后按 offset 增量追加
    final chunkResponse = await api.cronLogChunkRaw(
      widget.cronId,
      offset: _offset == 0 ? null : _offset,
      limit: 131072,
      tail: _offset == 0,
    );
    if (chunkResponse.success && chunkResponse.bean != null) {
      final Map<String, dynamic> map = chunkResponse.bean!;
      final String chunk = (map["data"] ?? "").toString();
      final int total = map["total"] is num ? (map["total"] as num).toInt() : 0;
      final int nextOffset = map["nextOffset"] is num
          ? (map["nextOffset"] as num).toInt()
          : 0;
      if (_offset > 0 && total < _offset) {
        // 日志已轮转或开始新一轮运行，重新读取
        content = chunk;
      } else {
        content = _offset == 0 ? chunk : "${content ?? ""}$chunk";
      }
      _offset = nextOffset > 0 ? nextOffset : _offset;
      response = HttpResponse(success: true, code: 200, bean: content);
    } else {
      /// 旧面板没有分块接口时回退整段读取
      response = await api.inTimeLog(widget.cronId);
      if (response.success) {
        content = response.bean;
        _offset = 0;
      }
    }

    if (!mounted) {
      return;
    }
    isRequest = false;
    if (response.success) {
      if (!mounted) {
        return;
      }
      content = response.bean;
      if (content == null || content!.isEmpty) return;

      String? found = ScanPageState.foundReg(
        widget.command ?? "",
        content ?? "",
      );
      if (found != null &&
          found.isNotEmpty &&
          widget.command != null &&
          (widget.command!.endsWith(".js") ||
              widget.command!.endsWith(".ts") ||
              widget.command!.endsWith(".py")) &&
          SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal) {
        Api api = Api(SingleAccountPageState.of(context)?.index ?? 0);
        var result = await ScanPageState.autoInstallFounded(
          api,
          found,
          widget.command!,
        );
        if (result == true) {
          "已安装依赖 $found".toast();
        }
      }
      if (alwaysAuthScroll) {
        if (!mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!mounted) {
            return;
          }
          if ((controller?.hasClients ?? false)) {
            controller!.animateTo(
              controller!.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
            );
          }
        });
      }
      if (!mounted) {
        return;
      }
      setState(() {});
    } else {
      if (!hasToastedFailed) {
        hasToastedFailed = true;
        response.message.toast();
      }
    }
  }

  bool hasToastedFailed = false;

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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: SelectableText(
                              content!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
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
      getLogData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        getLogData();
      });
    }
  }
}
