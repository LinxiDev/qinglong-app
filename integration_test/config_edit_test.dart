import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qinglong_app/main.dart' as app;
import 'package:qinglong_app/module/code_editor/codemirror/io.dart';

/// 配置文件编辑页：Android/iOS/桌面统一使用 re_editor 原生编辑器，
/// 页面可打开、内容进入编辑器、可正常返回，而不是抛异常或展示空白。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  bool ignorable(Object? e) {
    if (e == null) return true;
    if (e is MissingPluginException) return true;
    final String t = e.toString();
    return t.contains('MissingPlatformDirectoryException') ||
        t.contains('Unable to get application documents directory') ||
        t.contains('quick_actions') ||
        t.contains('local_auth') ||
        t.contains('fluttertoast') ||
        t.contains('showToast');
  }

  FlutterError.onError = (FlutterErrorDetails d) {
    if (ignorable(d.exception)) return;
    FlutterError.presentError(d);
  };

  Future<void> settle(WidgetTester tester, [int seconds = 3]) async {
    for (int i = 0; i < seconds * 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<bool> tapTab(WidgetTester tester, String label) async {
    final List<Element> elements = find.text(label).evaluate().toList();
    if (elements.isEmpty) return false;
    Element? best;
    double bestDy = -1;
    for (final Element e in elements) {
      final RenderObject? ro = e.renderObject;
      if (ro is! RenderBox || !ro.hasSize) continue;
      final double dy = ro.localToGlobal(Offset.zero).dy;
      if (dy > bestDy) {
        bestDy = dy;
        best = e;
      }
    }
    if (best == null) return false;
    await tester.tap(
      find.byElementPredicate((Element e) => identical(e, best)),
      warnIfMissed: false,
    );
    await settle(tester, 4);
    return true;
  }

  testWidgets('配置文件编辑页（原生编辑器）', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('CFG_EDIT: 未登录，跳过');
      ErrorWidget.builder = original;
      return;
    }

    await tapTab(tester, '配置文件');
    final Finder configSh = find.text('config.sh');
    expect(configSh, findsWidgets, reason: '配置文件列表应有 config.sh');

    // 双击进入编辑器（内容可能仍在加载，未打开则重试）
    for (int i = 0; i < 4; i++) {
      await tester.tap(configSh.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(configSh.first, warnIfMissed: false);
      await settle(tester, 4);
      if (find.text('编辑config.sh').evaluate().isNotEmpty) break;
    }

    expect(find.text('编辑config.sh'), findsOneWidget, reason: '应进入配置编辑页');

    // 原生编辑器为自绘组件，无 TextField；内容经 onCreate → setValue 进入控制器
    final CodeMirrorViewState state = tester.state<CodeMirrorViewState>(
      find.byType(CodeMirrorView),
    );
    expect(
      state.debugText.contains('#!/') || state.debugText.contains('export'),
      isTrue,
      reason: '编辑器应持有配置文件内容',
    );
    // ignore: avoid_print
    print('CFG_EDIT PASS: 编辑器内容长度=${state.debugText.length}');

    // 返回列表
    await tester.tap(
      find.byIcon(CupertinoIcons.left_chevron).first,
      warnIfMissed: false,
    );
    await settle(tester, 3);
    expect(find.text('编辑config.sh'), findsNothing, reason: '应返回配置文件列表');

    ErrorWidget.builder = original;
  });
}
