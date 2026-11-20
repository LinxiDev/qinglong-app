import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

import 'test_support.dart';

/// IP 黑名单增删回归（需已登录且面板版本 >= v2.22）。
///
/// IP 无法加文本前缀，固定使用 [testIp]，并在 tearDown 中强制移除。
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

  Future<bool> dragUntilFound(
    WidgetTester tester,
    Finder target, {
    int maxDrags = 6,
  }) async {
    for (int i = 0; i < maxDrags; i++) {
      if (target.evaluate().isNotEmpty) return true;
      final Size size = tester.getSize(find.byType(MaterialApp).first);
      await tester.dragFrom(
        Offset(size.width / 2, size.height * 0.62),
        const Offset(0, -240),
      );
      await settle(tester, 1);
    }
    return target.evaluate().isNotEmpty;
  }

  testWidgets('IP 黑名单增删', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    const String testIp = '10.0.0.3';

    // 成功失败都强制移除测试 IP
    addTearDown(() async {
      final String? token = await qaLogin();
      if (token == null) return;
      await qaApi(
        "DELETE",
        "/api/user/ip-blacklist",
        body: {"ip": testIp},
        token: token,
      );
    });

    // 预清理，避免上次中断残留导致重复添加
    final String? preToken = await qaLogin();
    if (preToken != null) {
      await qaApi(
        "DELETE",
        "/api/user/ip-blacklist",
        body: {"ip": testIp},
        token: preToken,
      );
    }

    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('IP_BL: 未登录，跳过');
      ErrorWidget.builder = original;
      return;
    }

    await tapTab(tester, '我的');
    final Finder entry = find.text('IP黑名单');
    final bool found = await dragUntilFound(tester, entry);
    expect(found, isTrue, reason: '我的页应能滚动到 IP黑名单 入口');

    await tester.tap(entry.first, warnIfMissed: false);
    await settle(tester, 5);
    expect(find.text('IP 黑名单'), findsOneWidget, reason: '应进入 IP 黑名单页');

    await tester.tap(
      find.byIcon(CupertinoIcons.add).first,
      warnIfMissed: false,
    );
    await settle(tester, 2);
    expect(find.text('添加 IP 黑名单'), findsOneWidget, reason: '应弹出添加对话框');

    await tester.enterText(find.byType(TextField).first, testIp);
    await tester.pump();
    await tester.tap(find.text('确定').last, warnIfMissed: false);
    await settle(tester, 5);
    expect(find.text(testIp), findsWidgets, reason: '新增后列表应出现该 IP');
    // ignore: avoid_print
    print('IP_BL 新增 $testIp 成功');

    await tester.tap(find.text('解除').first, warnIfMissed: false);
    await settle(tester, 5);
    expect(find.text(testIp), findsNothing, reason: '解除后列表应移除该 IP');
    // ignore: avoid_print
    print('IP_BL PASS: 新增/解除 $testIp 均生效');

    ErrorWidget.builder = original;
  });
}
