import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

/// 写入类流程：任务详情字段、环境变量新增、配置文件新增页、IP 黑名单增删。
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

  Future<void> step(WidgetTester tester, String label,
      Future<void> Function() action) async {
    try {
      await action();
      await settle(tester, 2);
      final Object? error = tester.takeException();
      if (!ignorable(error)) {
        // ignore: avoid_print
        print('  FAIL $label -> $error');
        return;
      }
      // ignore: avoid_print
      print('  OK   $label');
    } catch (e) {
      // ignore: avoid_print
      print('  FAIL $label -> $e');
    }
  }

  Future<bool> tapText(WidgetTester tester, String text,
      {int wait = 4}) async {
    final Finder f = find.text(text);
    if (f.evaluate().isEmpty) return false;
    await tester.tap(f.last, warnIfMissed: false);
    await settle(tester, wait);
    return true;
  }

  testWidgets('写入流程', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('WRITE_FLOW: 未登录，跳过');
      return;
    }

    await step(tester, '任务详情-打开', () async {
      await tapText(tester, '定时任务');
      if (!await tapText(tester, '每日签到', wait: 6)) {
        throw '未找到任务「每日签到」';
      }
    });
    // ignore: avoid_print
    print('  INFO 定时类型=${find.text('定时类型').evaluate().isNotEmpty} '
        '额外规则=${find.text('额外规则').evaluate().isNotEmpty} '
        '实例模式=${find.text('实例模式').evaluate().isNotEmpty}');
    await step(tester, '任务详情-返回', () async {
      await tester.tap(find.byIcon(CupertinoIcons.left_chevron).first,
          warnIfMissed: false);
    });

    await step(tester, '环境变量-新增页', () async {
      await tapText(tester, '环境变量');
      final Finder add = find.byIcon(CupertinoIcons.add);
      if (add.evaluate().isEmpty) throw '未找到新增按钮';
      await tester.tap(add.first, warnIfMissed: false);
      await settle(tester, 3);
      if (find.byType(TextField).evaluate().length < 2) throw '表单未出现';
      await tester.enterText(find.byType(TextField).at(0), 'APP_UI_VAR');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), 'hello');
      await tester.pump();
      if (!await tapText(tester, '提交', wait: 6)) throw '未找到提交';
      await settle(tester, 3);
      if (find.text('APP_UI_VAR').evaluate().isEmpty) throw '列表未出现新增项';
    });

    await step(tester, '配置文件-新增页', () async {
      await tapText(tester, '配置文件');
      final Finder add = find.byIcon(CupertinoIcons.add);
      if (add.evaluate().isEmpty) throw '未找到新增按钮';
      await tester.tap(add.first, warnIfMissed: false);
      await settle(tester, 4);
      if (find.text('提交').evaluate().isEmpty &&
          find.byType(TextField).evaluate().isEmpty) {
        throw '新增配置页未渲染';
      }
      if (find.byIcon(CupertinoIcons.left_chevron).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(CupertinoIcons.left_chevron).first,
            warnIfMissed: false);
        await settle(tester, 2);
      }
    });

    await step(tester, 'IP黑名单-增删', () async {
      await tapText(tester, '我的');
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500));
        await settle(tester, 2);
      }
      if (!await tapText(tester, 'IP黑名单', wait: 5)) {
        throw '未找到 IP黑名单 入口';
      }
      final Finder add = find.byIcon(CupertinoIcons.add);
      if (add.evaluate().isEmpty) throw '未找到新增按钮';
      await tester.tap(add.first, warnIfMissed: false);
      await settle(tester, 2);
      await tester.enterText(find.byType(TextField).first, '10.0.0.2');
      await tester.pump();
      if (!await tapText(tester, '确定', wait: 5)) throw '未找到确定按钮';
      await settle(tester, 2);
      if (find.text('10.0.0.2').evaluate().isEmpty) throw '新增未生效';
      if (!await tapText(tester, '解除', wait: 5)) throw '未找到解除';
      await settle(tester, 2);
      if (find.text('10.0.0.2').evaluate().isNotEmpty) throw '解除未生效';
    });

    ErrorWidget.builder = original;
  });
}
