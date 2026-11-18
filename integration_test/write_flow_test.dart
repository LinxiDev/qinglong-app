import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

/// 环境变量新增回归（需已登录的真实面板）。
///
/// 断言提交成功后新增页自动关闭且列表出现新变量。
/// 测试数据 TEST_UI_VAR 需在用例结束后通过接口清理，避免污染面板。
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

  testWidgets('环境变量新增', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('ENV_ADD: 未登录，跳过');
      ErrorWidget.builder = original;
      return;
    }

    await tapTab(tester, '环境变量');
    expect(
      find.byIcon(CupertinoIcons.add),
      findsWidgets,
      reason: '环境变量页应存在右上角新增按钮',
    );

    await tester.tap(
      find.byIcon(CupertinoIcons.add).first,
      warnIfMissed: false,
    );
    await settle(tester, 3);
    expect(find.text('新增环境变量'), findsOneWidget, reason: '应进入新增环境变量页');
    expect(
      find.byType(TextField).evaluate().length,
      greaterThanOrEqualTo(2),
      reason: '表单应有名称与值两个输入框',
    );

    final String suffix = '${DateTime.now().millisecondsSinceEpoch % 100000}';
    final String envName = 'TEST_UI_VAR_$suffix';
    final String envValue = 'hello_$suffix';
    await tester.enterText(find.byType(TextField).at(0), envName);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), envValue);
    await tester.pump();
    await tester.tap(find.text('提交').last, warnIfMissed: false);
    await settle(tester, 8);

    expect(find.text('新增环境变量'), findsNothing, reason: '提交成功后应自动返回列表页');
    // 列表里名称可能被高亮文本包裹，这里用唯一的值做断言
    expect(find.text(envValue), findsWidgets, reason: '列表应出现新增变量');
    // ignore: avoid_print
    print('ENV_ADD PASS: $envName 新增成功且已返回列表');

    // 长按打开操作菜单，确认菜单项渲染正常后关闭
    await tester.longPress(find.text(envValue).first);
    await settle(tester, 2);
    expect(find.text('重命名变量名'), findsWidgets, reason: '长按应弹出操作菜单');
    final Finder barrier = find.byType(ModalBarrier);
    if (barrier.evaluate().isNotEmpty) {
      await tester.tap(barrier.last, warnIfMissed: false);
      await settle(tester, 2);
    }
    expect(find.text('重命名变量名'), findsNothing, reason: '菜单应可关闭');
    // ignore: avoid_print
    print('ENV_MENU PASS: 长按菜单打开/关闭正常');

    ErrorWidget.builder = original;
  });
}
