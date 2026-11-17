import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

/// 配置文件新增页回归（需已登录的真实面板）。
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
    await tester.tap(find.byElementPredicate((Element e) => identical(e, best)),
        warnIfMissed: false);
    await settle(tester, 4);
    return true;
  }

  testWidgets('配置文件新增页', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('CFG_ADD: 未登录，跳过');
      ErrorWidget.builder = original;
      return;
    }

    await tapTab(tester, '配置文件');
    expect(find.byIcon(CupertinoIcons.add), findsWidgets,
        reason: '配置文件页应存在右上角新增按钮');

    await tester.tap(find.byIcon(CupertinoIcons.add).first, warnIfMissed: false);
    await settle(tester, 4);

    expect(find.text('新增配置文件'), findsOneWidget, reason: '应进入新增配置文件页');
    expect(find.byType(TextField), findsWidgets, reason: '新增页应有名称输入框');
    expect(find.text('提交'), findsWidgets, reason: '新增页应有提交按钮');

    // ignore: avoid_print
    print('CFG_ADD PASS: 新增配置文件页渲染正常（名称输入框 + 提交）');
    ErrorWidget.builder = original;
  });
}
