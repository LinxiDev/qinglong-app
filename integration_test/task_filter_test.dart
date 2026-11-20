import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

import 'test_support.dart';

/// 任务列表分页 + 状态 Tab 服务端筛选回归（需已登录的真实面板）。
///
/// 直接用 HTTP 预置 21 条 qa_ui_ 任务（3 条禁用），测试结束全部删除。
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

  /// 搜索框是 CupertinoTextField，用 EditableText 定位并把列表限定到测试数据
  Future<void> enterSearch(WidgetTester tester, String keyword) async {
    final Finder fields = find.byType(EditableText).hitTestable();
    if (fields.evaluate().isEmpty) return;
    await tester.enterText(fields.first, keyword);
    await settle(tester, 5);
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

  Future<void> dragUp(WidgetTester tester, {int times = 8}) async {
    final Size size = tester.getSize(find.byType(MaterialApp).first);
    for (int i = 0; i < times; i++) {
      await tester.dragFrom(
        Offset(size.width / 2, size.height * 0.72),
        const Offset(0, -600),
      );
      await settle(tester, 1);
    }
  }

  testWidgets('任务分页与状态 Tab', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    List<int> ids = [];
    String? token;

    // 统一标识：qa_ui_task_<runId>_，统计与清理都限定在该命名空间内
    const String taskPrefix = '${qaPrefix}task_';
    final String runId = qaRunId();
    final String firstName = '$taskPrefix${runId}_20';
    final String lastName = '$taskPrefix${runId}_0';

    // 断言失败时 finally 可能还没拿到 ids，tearDown 再按前缀兜底清理一次
    addTearDown(() async {
      if (token == null) return;
      final Map<String, dynamic> result = await api(
        "GET",
        "/api/crons?page=1&size=100&searchValue=$taskPrefix",
        token: token,
      );
      final List<int> cleanupIds =
          (((result["data"] as Map?)?["data"] as List?) ?? [])
              .whereType<Map>()
              .where(
                (e) => (e["name"]?.toString() ?? "").startsWith(taskPrefix),
              )
              .map((e) => e["id"])
              .whereType<int>()
              .toList();
      if (cleanupIds.isNotEmpty) {
        await api("DELETE", "/api/crons", body: cleanupIds, token: token);
      }
    });

    try {
      /// 预置数据（App 启动前完成，避免依赖页面刷新）
      final Map<String, dynamic> login = await api(
        "POST",
        "/api/user/login",
        body: {
          "username": Platform.environment["QL_USER"] ?? "admin",
          "password": Platform.environment["QL_PASS"] ?? "123",
        },
      );
      token = (login["data"] as Map?)?["token"]?.toString();
      if (token == null || token.isEmpty) {
        // ignore: avoid_print
        print('TASK_FILTER: 面板登录失败，跳过');
        return;
      }

      /// 先清理历史残留，保证下面的计数断言不受上次失败/并发任务影响
      final Map<String, dynamic> stale = await api(
        "GET",
        "/api/crons?page=1&size=100&searchValue=$taskPrefix",
        token: token,
      );
      final List<int> staleIds =
          (((stale["data"] as Map?)?["data"] as List?) ?? [])
              .whereType<Map>()
              .where(
                (e) => (e["name"]?.toString() ?? "").startsWith(taskPrefix),
              )
              .map((e) => e["id"])
              .whereType<int>()
              .toList();
      if (staleIds.isNotEmpty) {
        await api("DELETE", "/api/crons", body: staleIds, token: token);
      }

      for (int i = 0; i < 21; i++) {
        await api(
          "POST",
          "/api/crons",
          body: {
            "name": '$taskPrefix${runId}_$i',
            "command": "echo $taskPrefix${runId}_$i",
            "schedule": "0 0 1 1 *",
          },
          token: token,
        );
      }
      final Map<String, dynamic> list = await api(
        "GET",
        "/api/crons?page=1&size=100&searchValue=$taskPrefix",
        token: token,
      );
      final List<dynamic> items =
          ((list["data"] as Map?)?["data"] as List?) ?? [];
      ids = items.map((e) => e["id"]).whereType<int>().toList();
      final List<int> disabled = items
          .where(
            (e) =>
                e is Map &&
                [
                  '$taskPrefix${runId}_0',
                  '$taskPrefix${runId}_1',
                  '$taskPrefix${runId}_2',
                ].contains(e["name"]),
          )
          .map((e) => e["id"])
          .whereType<int>()
          .toList();
      expect(ids.length, greaterThanOrEqualTo(21), reason: '测试任务应创建成功');
      expect(disabled.length, 3, reason: '应找到 3 条待禁用任务');
      await api("PUT", "/api/crons/disable", body: disabled, token: token);

      /// API 层断言：分页与状态筛选（不依赖 App 登录态）
      final Map<String, dynamic> page1 = await api(
        "GET",
        "/api/crons?page=1&size=20&searchValue=$taskPrefix",
        token: token,
      );
      final Map<String, dynamic> page1Data = Map<String, dynamic>.from(
        (page1["data"] as Map?) ?? <String, dynamic>{},
      );
      expect((page1Data["data"] as List).length, 20, reason: '每页应返回 20 条');
      expect(
        ((page1Data["total"] as num?) ?? 0).toInt(),
        greaterThanOrEqualTo(21),
        reason: 'total 应包含全部测试任务',
      );

      final Map<String, dynamic> page2 = await api(
        "GET",
        "/api/crons?page=2&size=20&searchValue=$taskPrefix",
        token: token,
      );
      expect(
        ((page2["data"] as Map?)?["data"] as List).isNotEmpty,
        isTrue,
        reason: '第二页应有剩余任务',
      );

      final Map<String, dynamic> idle = await api(
        "GET",
        "/api/crons?page=1&size=100&searchValue=$taskPrefix&filters="
            "${Uri.encodeQueryComponent(jsonEncode({
              "status": [1],
            }))}",
        token: token,
      );
      expect(
        (((idle["data"] as Map?)?["total"] as num?) ?? 0).toInt(),
        18,
        reason: '空闲中应有 18 条（21 条中禁用 3 条）',
      );

      final Map<String, dynamic> disabledFilter = await api(
        "GET",
        "/api/crons?page=1&size=100&searchValue=$taskPrefix&filters="
            "${Uri.encodeQueryComponent(jsonEncode({
              "status": [2],
            }))}",
        token: token,
      );
      expect(
        (((disabledFilter["data"] as Map?)?["total"] as num?) ?? 0).toInt(),
        3,
        reason: '已禁用应有 3 条',
      );

      app.main();
      await settle(tester, 12);

      if (find.text('账号登录').evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('TASK_FILTER: 应用未登录，跳过 UI 断言');
        return;
      }

      await tapTab(tester, '定时任务');
      await settle(tester, 4);
      // 把列表限定到测试数据，避免演示面板自带任务影响分页与状态 Tab
      await enterSearch(tester, taskPrefix);

      /// 默认排序按创建时间倒序：首屏最后一条，第二页才出现第一条
      expect(
        find.textContaining(firstName).evaluate().isNotEmpty,
        isTrue,
        reason: '第一页应包含 $firstName',
      );
      expect(
        find.textContaining(lastName).evaluate().isEmpty,
        isTrue,
        reason: '第二页任务不应在首屏全部渲染',
      );

      await dragUp(tester);
      expect(
        find.textContaining(lastName).evaluate().isNotEmpty,
        isTrue,
        reason: '滚动到底应自动加载第二页任务',
      );

      /// 已禁用 Tab 走服务端 filters
      await tapTab(tester, '已禁用');
      await settle(tester, 4);
      expect(
        find.textContaining(lastName).evaluate().isNotEmpty,
        isTrue,
        reason: '已禁用 Tab 应包含被禁用的 $lastName',
      );

      // ignore: avoid_print
      print('TASK_FILTER PASS: 分页与状态筛选正常');
    } finally {
      if (ids.isNotEmpty && token != null) {
        await api("DELETE", "/api/crons", body: ids, token: token);
      }
      ErrorWidget.builder = original;
    }
  });
}
