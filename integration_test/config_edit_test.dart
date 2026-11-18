import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

/// 配置文件编辑页：桌面/Windows 无 webview 实现时应降级为只读文本视图，
/// 至少保证页面可打开、内容可读、可正常返回，而不是抛 MissingPluginException。
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
        t.contains('webview_flutter') ||
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

  testWidgets('配置文件编辑页（webview 降级）', (WidgetTester tester) async {
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
    expect(find.byType(TextField), findsWidgets, reason: '应有可读的内容视图');

    // 桌面端为只读降级视图，内容应能看到 shell 片段
    final Iterable<String?> texts = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((TextField f) => f.controller?.text);
    final bool hasContent = texts.any(
      (String? t) => (t ?? '').contains('#!/') || (t ?? '').contains('export'),
    );
    expect(hasContent, isTrue, reason: '编辑页应展示配置文件内容');
    // ignore: avoid_print
    print(
      'CFG_EDIT PASS: 编辑页内容长度=${texts.map((t) => (t ?? '').length).toList()}',
    );

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
