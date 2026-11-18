import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../base/theme.dart';
import 'impl.dart';

class CodeMirrorView extends CodeMirrorViewImpl {
  final CodeMirrorOptions options;

  final ValueChanged<EditorController> onCreate;

  final Function(String val) onValue;

  const CodeMirrorView({
    super.key,
    required this.options,
    required this.onCreate,
    required this.onValue,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return CodeMirrorViewState();
  }
}

class CodeMirrorViewState extends CodeMirrorViewImplState<CodeMirrorView> {
  String getHtml(String raw) {
    String html = raw;
    html = html.replaceAll('VERSION', '5.65.6');
    html = html.replaceAll('EDITOR_THEME', widget.options.theme);
    html = html.replaceAll('EDITOR_MODE', widget.options.mode);
    return Uri.dataFromString(html, mimeType: 'text/html').toString();
  }

  WebViewController? _controller;

  bool readOnly = false;
  bool isLoaded = false;

  static bool isLoadedJs = false;
  bool isShowSearch = false;

  Size _size = Size.zero;
  String _rawHtml = "";

  TextEditingController? _fallbackController;

  /// Windows / Linux 没有 webview_flutter 的原生实现，
  /// 用只读文本视图兜底，避免编辑器页面直接抛 MissingPluginException
  static bool get _webViewSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _ensureFallback() {
    if (_fallbackController != null) return;
    _fallbackController = TextEditingController();
    isLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onCreate(
        EditorController(
          setValue: (String val) {
            _fallbackController?.text = val;
          },
          setOptions: (CodeMirrorOptions val) {
            readOnly = val.readOnly;
          },
          refresh: () {},
        ),
      );
    });
  }

  Widget _buildFallback() {
    _ensureFallback();
    return Container(
      color: ref.read(themeProvider).themeColor.codeBgColor(),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _fallbackController,
        readOnly: true,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "当前平台不支持代码高亮编辑器，以下为只读内容",
        ),
      ),
    );
  }

  Future<void> showSearchBar() async {
    if (isShowSearch) {
      await _controller?.runJavaScript('clearSearchText()');
    } else {
      await _controller?.runJavaScript('searchText()');
    }
    isShowSearch = !isShowSearch;
  }

  void _resize() {
    if (!isLoaded) return;
    _controller?.runJavaScript(
      'editor.setSize(${_size.width},${_size.height})',
    );
  }

  void _ensureController() {
    if (_controller != null) return;

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(ref.read(themeProvider).themeColor.codeBgColor())
      ..addJavaScriptChannel(
        'MessageInvoker',
        onMessageReceived: (JavaScriptMessage message) =>
            widget.onValue(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _resize();
            widget.onCreate(
              EditorController(
                setOptions: (val) async {
                  readOnly = val.readOnly;
                  _resize();

                  await _controller?.runJavaScript(
                    'editor.setOption("mode", "${val.mode}")',
                  );
                  await _controller?.runJavaScript(
                    'editor.setOption("theme", "${val.theme}")',
                  );
                  await _controller?.runJavaScript(
                    'editor.setOption("readOnly", ${val.readOnly ? '"nocursor"' : false})',
                  );
                  await _controller?.runJavaScript(
                    'editor.setOption("lineNumbers", ${val.showLineNumber})',
                  );
                  await Future.delayed(const Duration(milliseconds: 200));
                  await _controller?.runJavaScript('editor.refresh()');
                  await EasyLoading.dismiss();
                  if (widget.options.mode != val.mode ||
                      widget.options.theme != val.theme) {
                    await _controller?.loadRequest(
                      Uri.parse(getHtml(_rawHtml)),
                    );
                  }
                },
                setValue: (val) async {
                  isLoaded = true;
                  final raw = Uri.encodeComponent(val);
                  await _controller?.runJavaScript(
                    'editor.setValue(decodeURIComponent("$raw"))',
                  );
                },
                refresh: () async {
                  const delay = Duration(milliseconds: 50);
                  await Future.delayed(delay);
                  await _controller?.runJavaScript('editor.refresh()');
                },
              ),
            );
          },
        ),
      );

    _controller = controller;

    if (MultiAccountPageState.useAction().isEmpty) {
      if (!isLoadedJs) {
        isLoadedJs = true;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          EasyLoading.show(status: "加载中");
        });
      }
    }

    controller.loadRequest(Uri.parse(getHtml(_rawHtml)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/codemirror.html'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: LoadingWidget());
        }
        _rawHtml = snapshot.data ?? "";
        return LayoutBuilder(
          builder: (context, dimens) {
            _size = Size(dimens.maxWidth, dimens.maxHeight);
            return KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                if (!_webViewSupported) {
                  return _buildFallback();
                }
                _ensureController();
                _resize();

                return WebViewWidget(controller: _controller!);
              },
            );
          },
        );
      },
    );
  }
}
