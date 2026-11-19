import 'dart:convert';
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/main.dart' as app;

/// 环境变量标签回归（需可登录的真实面板）。
///
/// 直接用 HTTP 创建变量并设置 #qa 标签，UI 断言尽力而为，
/// 测试结束删除临时变量。
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

  testWidgets('环境变量标签', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    List<int> ids = [];
    String? token;

    try {
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
        print('ENV_LABEL: 面板登录失败，跳过');
        return;
      }

      await api(
        "POST",
        "/api/envs",
        body: [
          {"name": "qa_ui_env", "value": "1", "remarks": "qa automation"},
        ],
        token: token,
      );
      final Map<String, dynamic> envList = await api(
        "GET",
        "/api/envs?searchValue=qa_ui_env",
        token: token,
      );
      final List<dynamic> envs = (envList["data"] as List?) ?? [];
      ids = envs
          .whereType<Map>()
          .where((e) => e["name"] == "qa_ui_env")
          .map((e) => e["id"])
          .whereType<int>()
          .toList();
      expect(ids.isNotEmpty, isTrue, reason: '测试变量应创建成功');

      /// 设置标签并验证接口返回
      await api(
        "POST",
        "/api/envs/labels",
        body: {
          "ids": ids,
          "labels": ["qa"],
        },
        token: token,
      );
      final Map<String, dynamic> labeled = await api(
        "GET",
        "/api/envs?searchValue=qa_ui_env",
        token: token,
      );
      final List<dynamic> labeledEnvs = (labeled["data"] as List?) ?? [];
      final Map? bean = labeledEnvs
          .whereType<Map>()
          .where((e) => e["name"] == "qa_ui_env")
          .firstOrNull;
      expect(bean, isNotNull, reason: '应能查询到测试变量');
      expect(
        (bean!["labels"] as List?)?.contains("qa"),
        isTrue,
        reason: '变量 labels 应包含 qa',
      );

      app.main();
      await settle(tester, 12);

      if (find.text('账号登录').evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('ENV_LABEL: 应用未登录，跳过 UI 断言');
        return;
      }

      await tapTab(tester, '环境变量');
      await settle(tester, 5);
      expect(
        find
            .textContaining('qa_ui_env', findRichText: true)
            .evaluate()
            .isNotEmpty,
        isTrue,
        reason: '环境变量列表应展示测试变量',
      );
      expect(
        find.textContaining('#qa', findRichText: true).evaluate().isNotEmpty,
        isTrue,
        reason: '变量行应展示 #qa 标签',
      );

      // ignore: avoid_print
      print('ENV_LABEL PASS: 变量与标签正常');
    } finally {
      if (ids.isNotEmpty && token != null) {
        await api("DELETE", "/api/envs", body: ids, token: token);
      }
      ErrorWidget.builder = original;
    }
  });
}
