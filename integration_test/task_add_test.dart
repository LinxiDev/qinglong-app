import 'dart:convert';
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

import 'test_support.dart';

/// 新增定时任务：验证 名称/命令/定时规则 能提交成功并回读到列表。
///
/// 创建 `qa_ui_task_add_<runId>`，tearDown 中通过接口删除。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String defaultHost = "http://demo.qinglong.online:4433";

  String host() => Platform.environment["QL_HOST"] ?? defaultHost;

  Future<Map<String, dynamic>> api(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.openUrl(
        method,
        Uri.parse(host() + path),
      );
      request.headers.contentType = ContentType.json;
      if (token != null) {
        request.headers.set("Authorization", "Bearer $token");
      }
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final HttpClientResponse response = await request.close();
      final String text = await utf8.decoder.bind(response).join();
      final dynamic decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    } finally {
      client.close();
    }
  }

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

  testWidgets('新增定时任务', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    String? token;
    final String name = '${qaPrefix}task_add_${qaRunId()}';

    // 无论断言是否失败都按统一前缀清理测试任务
    addTearDown(() async {
      if (token == null) return;
      final Map<String, dynamic> created = await api(
        "GET",
        "/api/crons?page=1&size=100&searchValue=$name",
        token: token,
      );
      final List<int> cleanupIds =
          (((created["data"] as Map?)?["data"] as List?) ?? [])
              .whereType<Map>()
              .where((e) => e["name"] == name)
              .map((e) => e["id"])
              .whereType<int>()
              .toList();
      if (cleanupIds.isNotEmpty) {
        await api("DELETE", "/api/crons", body: cleanupIds, token: token);
      }
    });

    app.main();
    await settle(tester, 10);

    if (find.text('账号登录').evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('TASK_ADD: 未登录，跳过');
      ErrorWidget.builder = original;
      return;
    }

    await tapTab(tester, '定时任务');
    expect(
      find.byIcon(CupertinoIcons.add),
      findsWidgets,
      reason: '定时任务页应有新增按钮',
    );

    await tester.tap(
      find.byIcon(CupertinoIcons.add).first,
      warnIfMissed: false,
    );
    await settle(tester, 4);
    expect(find.text('新增任务'), findsOneWidget, reason: '应进入新增任务页');

    final List<TextField> fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.length, greaterThanOrEqualTo(3), reason: '应有名称/命令/定时三个输入框');

    await tester.enterText(find.byType(TextField).at(0), name);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'echo ui_test');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), '0 3 * * *');
    await tester.pump();

    await tester.tap(find.text('提交').last, warnIfMissed: false);
    await settle(tester, 8);

    // 获取 token；tearDown 会按名称回查并删除
    final Map<String, dynamic> login = await api(
      "POST",
      "/api/user/login",
      body: {
        "username": Platform.environment["QL_USER"] ?? "admin",
        "password": Platform.environment["QL_PASS"] ?? "123",
      },
    );
    token = (login["data"] as Map?)?["token"]?.toString();

    expect(find.text('新增任务'), findsNothing, reason: '提交成功后应返回列表');
    expect(find.text(name), findsWidgets, reason: '列表应出现新任务');
    // ignore: avoid_print
    print('TASK_ADD PASS: $name 新增成功且已返回列表');

    ErrorWidget.builder = original;
  });
}
