import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

/// 空态回归：面板无任务 / 环境变量 / 配置文件时应展示空态占位。
///
/// 需要面板处于“空数据”状态（CI 上新建的面板天然满足）。
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

  testWidgets('空数据时三个列表页展示空态', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('EMPTY_STATE: 未登录，跳过');
      ErrorWidget.builder = original;
      return;
    }

    for (final String tab in <String>['定时任务', '环境变量']) {
      expect(await tapTab(tester, tab), isTrue, reason: '应能切换到 $tab');
      expect(find.text('暂无数据'), findsWidgets, reason: '$tab 在无数据时应展示空态占位');
      // ignore: avoid_print
      print('EMPTY_STATE PASS: $tab 空态正常');
    }

    // 配置文件页在面板初始化后就自带 config.sh 等文件，不会出现空态
    expect(await tapTab(tester, '配置文件'), isTrue);
    expect(find.text('config.sh'), findsWidgets, reason: '配置文件列表应展示默认文件');
    // ignore: avoid_print
    print('EMPTY_STATE PASS: 配置文件列表正常');

    ErrorWidget.builder = original;
  });
}
