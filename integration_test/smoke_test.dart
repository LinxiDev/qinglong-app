import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qinglong_app/main.dart' as app;

/// 在 Linux 桌面上真实运行 App，按入口遍历主要页面，
/// 断言每一步都没有未捕获异常。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 桌面端缺少 quick_actions / local_auth 等插件实现，忽略这类平台异常
  bool ignorable(Object? e) {
    if (e == null) return true;
    if (e is MissingPluginException) return true;
    final String text = e.toString();
    return text.contains('MissingPlatformDirectoryException') ||
        text.contains('Unable to get application documents directory') ||
        text.contains('quick_actions') ||
        text.contains('local_auth') ||
        text.contains('webview_flutter');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    if (ignorable(details.exception)) return;
    FlutterError.presentError(details);
  };

  final List<String> visited = <String>[];
  final List<String> failed = <String>[];

  Future<void> settle(WidgetTester tester, [int seconds = 3]) async {
    for (int i = 0; i < seconds * 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> capture(WidgetTester tester, String label) async {
    final Object? error = tester.takeException();
    if (!ignorable(error)) {
      failed.add('$label -> $error');
    } else {
      visited.add(label);
    }
  }

  Future<bool> tapText(WidgetTester tester, String text) async {
    final Finder finder = find.text(text);
    if (finder.evaluate().isEmpty) return false;
    await tester.tap(finder.last, warnIfMissed: false);
    await settle(tester, 3);
    await capture(tester, text);
    // 弹窗型入口（如日志设置），关闭弹窗即视为通过
    final Finder cancel = find.text('取消');
    if (cancel.evaluate().isNotEmpty) {
      await tester.tap(cancel.last, warnIfMissed: false);
      await settle(tester, 1);
      return true;
    }
    // 确认真的进入了二级页面（有返回箭头）
    if (find.byIcon(CupertinoIcons.left_chevron).evaluate().isEmpty) {
      failed.add('$text -> 未进入页面');
      return false;
    }
    return true;
  }

  Future<void> goBack(WidgetTester tester) async {
    final Finder backIcon = find.byIcon(CupertinoIcons.left_chevron);
    if (backIcon.evaluate().isEmpty) return;
    await tester.tap(backIcon.first, warnIfMissed: false);
    await settle(tester, 2);
    await capture(tester, '<返回>');
  }

  Future<void> scrollDown(WidgetTester tester) async {
    final Finder scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return;
    await tester.drag(scrollable.first, const Offset(0, -500));
    await settle(tester, 1);
  }

  testWidgets('遍历主要页面', (WidgetTester tester) async {
    final ErrorWidgetBuilder originalErrorBuilder = ErrorWidget.builder;
    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('APP_SMOKE: 未登录（token 失效），仅验证登录页可渲染');
      return;
    }

    // 我的（底部 tab，不校验返回箭头）
    await tester.tap(find.text('我的').last, warnIfMissed: false);
    await settle(tester, 4);
    await capture(tester, '我的');

    // 脚本 / 依赖 / 订阅（位于我的页顶部卡片，先点再滚动）
    for (final String page in <String>['脚本管理', '依赖管理', '订阅管理']) {
      if (await tapText(tester, page)) {
        await goBack(tester);
      } else {
        failed.add('$page -> 入口未找到');
      }
    }

    await scrollDown(tester);

    const List<String> pages = <String>[
      '任务日志',
      '登录日志',
      '应用设置',
      '通知设置',
      '修改密码',
      '日志设置',
      '系统设置',
      '关于软件',
      '扫描依赖',
      '字体大小',
      '账号排序',
      '运行概览',
      '通知日志',
      '数据清理',
      'IP黑名单',
    ];

    for (final String page in pages) {
      bool found = false;
      for (int i = 0; i < 4 && !found; i++) {
        found = await tapText(tester, page);
        if (!found) {
          await scrollDown(tester);
        }
      }
      if (!found) {
        failed.add('$page -> 入口未找到');
        continue;
      }
      await goBack(tester);
    }

    // ignore: avoid_print
    print('APP_SMOKE visited=${visited.length} failed=${failed.length}');
    for (final String item in visited) {
      // ignore: avoid_print
      print('  OK   $item');
    }
    for (final String item in failed) {
      // ignore: avoid_print
      print('  FAIL $item');
    }
    ErrorWidget.builder = originalErrorBuilder;
    expect(failed, isEmpty, reason: '存在页面异常: $failed');
  });
}
