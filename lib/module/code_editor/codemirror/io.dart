import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/plaintext.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../../base/theme.dart';
import 'impl.dart';

/// 基于 re_editor 的原生代码编辑器（替代原 WebView + CodeMirror 方案）。
///
/// 对外保持与旧 WebView 实现完全一致的公开契约，六个页面零改动：
/// - [CodeMirrorView] / [CodeMirrorViewState]（页面持有 GlobalKey 调用 showSearchBar）
/// - [EditorController]（setValue / setOptions / refresh）
///
/// 键盘输入走 Flutter 原生输入管线，Android/iOS 键盘动画不再有
/// 平台视图合成与视口重排导致的卡顿；桌面端也不再需要只读兜底。
class CodeMirrorView extends ConsumerStatefulWidget {
  final CodeMirrorOptions options;
  final ValueChanged<EditorController> onCreate;
  final void Function(String val) onValue;

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

class CodeMirrorViewState extends ConsumerState<CodeMirrorView> {
  late CodeLineEditingController _controller;
  late CodeFindController _findController;
  CodeMirrorOptions? _options;
  bool _created = false;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _controller = CodeLineEditingController.fromText('');
    _controller.addListener(_notifyValue);
    _findController = CodeFindController(_controller);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted || _created) {
        return;
      }
      _created = true;
      widget.onCreate(
        EditorController(
          setValue: _setValue,
          setOptions: _setOptions,
          // 原生编辑器布局自适应，无需手动 refresh
          refresh: () {},
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant CodeMirrorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.options, widget.options)) {
      _options = widget.options;
    }
  }

  String _lastText = '';

  void _notifyValue() {
    final String text = _controller.text;
    // 控制器在选中区变化时也会通知，过滤掉，对齐旧 CodeMirror 仅 change 事件
    if (text == _lastText) {
      return;
    }
    _lastText = text;
    widget.onValue(text);
  }

  void _setValue(String val) {
    _lastText = val;
    // 同步赋值：文档要求仅在帧间调用，页面 onCreate/回调均满足。
    // 之前用 textAsync 存在竞态——异步解析落地前键盘弹出触发重建，内容丢失。
    _controller.text = val;
  }

  /// 仅供测试读取当前文本（验证页面装配路径内容是否进入编辑器）
  @visibleForTesting
  String get debugText => _controller.text;

  void _setOptions(CodeMirrorOptions val) {
    setState(() {
      _options = val;
    });
  }

  /// 对齐旧 CodeMirrorViewState.showSearchBar：开/关查找面板
  void showSearchBar() {
    if (_findController.value == null) {
      _findController.value = CodeFindValue(
        option: const CodeFindOption(
          pattern: '',
          caseSensitive: false,
          regex: false,
        ),
        replaceMode: false,
        searching: true,
      );
    } else {
      _findController.close();
    }
  }

  /// 语法模式 key → re_highlight 语言规则（与 impl.dart 的
  /// [kFileExtensionLanguages] 配套；新增类型在此表加一项）
  static final Map<String, Mode> _languageModeRules = {
    'bash': langBash,
    'shell': langBash,
    'python': langPython,
    'javascript': langJavascript,
    'typescript': langTypescript,
    'json': langJson,
    'plaintext': langPlaintext,
  };

  Mode _modeForLanguageKey(String key) {
    return _languageModeRules[key] ?? langPlaintext;
  }

  @override
  Widget build(BuildContext context) {
    final CodeMirrorOptions options = _options ?? widget.options;
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final Color primary = ref.watch(themeProvider).primaryColor;
    final themeColor = ref.watch(themeProvider).themeColor;

    // 高亮主题：深浅色各一套（atom-one 系），root 节点提供编辑器底色与文字色
    final Map<String, TextStyle> hlTheme = dark
        ? atomOneDarkTheme
        : atomOneLightTheme;
    final TextStyle rootStyle = hlTheme['root'] ?? const TextStyle();
    final Color backgroundColor =
        rootStyle.backgroundColor ?? themeColor.codeBgColor();
    final Color textColor = rootStyle.color ?? themeColor.titleColor();

    final codeTheme = CodeHighlightTheme(
      languages: {
        options.mode: CodeHighlightThemeMode(
          mode: _modeForLanguageKey(options.mode),
        ),
      },
      theme: hlTheme,
    );

    return CodeEditor(
      controller: _controller,
      findController: _findController,
      readOnly: options.readOnly,
      // 保持与旧 CodeMirror lineWrapping: true 一致的自动换行行为
      wordWrap: true,
      style: CodeEditorStyle(
        codeTheme: codeTheme,
        fontSize: 14,
        fontHeight: 1.45,
        backgroundColor: backgroundColor,
        textColor: textColor,
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.30),
        highlightColor: primary.withValues(alpha: 0.20),
        cursorLineColor: primary.withValues(alpha: 0.08),
      ),
      indicatorBuilder: options.showLineNumber
          ? (context, editingController, chunkController, notifier) {
              // 行号/折叠列纳入编辑器点击组并设为 opaque：
              // TapRegion 默认 deferToChild，而行号是叶子渲染对象不可命中，
              // 点击行号会被判为「编辑器外」触发 onTapOutside 立即 unfocus，
              // 表现为键盘弹出后马上收回。
              return CodeEditorTapRegion(
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    DefaultCodeLineNumber(
                      controller: editingController,
                      notifier: notifier,
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? const Color(0xff4b5263)
                            : const Color(0xffa6b3c0),
                      ),
                      focusedTextStyle: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? const Color(0xffabb2bf)
                            : const Color(0xff24292f),
                      ),
                    ),
                    DefaultCodeChunkIndicator(
                      width: 16,
                      controller: chunkController,
                      notifier: notifier,
                    ),
                  ],
                ),
              );
            }
          : null,
      findBuilder: (context, controller, readonly) {
        if (controller.value == null) {
          return const PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: SizedBox.shrink(),
          );
        }
        return PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FindPanel(
            controller: controller,
            dark: dark,
            primary: primary,
          ),
        );
      },
      padding: const EdgeInsets.symmetric(vertical: 6),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_notifyValue);
    _findController.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// 查找面板：对齐旧 CodeMirror findPersistent 的常用能力
/// （查找输入、上一个/下一个、区分大小写、关闭）。
class _FindPanel extends StatelessWidget {
  final CodeFindController controller;
  final bool dark;
  final Color primary;

  const _FindPanel({
    required this.controller,
    required this.dark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = dark ? const Color(0xff21252b) : const Color(0xfff0f1f3);
    final Color fg = dark ? const Color(0xffabb2bf) : const Color(0xff24292f);
    final Color border = fg.withValues(alpha: 0.20);
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: border),
    );

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller.findInputController,
                  focusNode: controller.findInputFocusNode,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, color: fg),
                  cursorColor: primary,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => controller.nextMatch(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '查找内容',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: fg.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: primary),
                    ),
                  ),
                ),
              ),
              _PanelIcon(
                icon: Icons.keyboard_arrow_up,
                color: fg,
                tooltip: '上一个',
                onTap: controller.previousMatch,
              ),
              _PanelIcon(
                icon: Icons.keyboard_arrow_down,
                color: fg,
                tooltip: '下一个',
                onTap: controller.nextMatch,
              ),
              _PanelIcon(
                icon: Icons.text_fields,
                color: fg,
                tooltip: '区分大小写',
                onTap: controller.toggleCaseSensitive,
              ),
              _PanelIcon(
                icon: Icons.close,
                color: fg,
                tooltip: '关闭',
                onTap: controller.close,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _PanelIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: color),
      onPressed: onTap,
    );
  }
}
