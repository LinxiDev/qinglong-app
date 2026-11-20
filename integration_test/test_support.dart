import 'dart:convert';
import 'dart:io';

/// 集成测试统一约定：
/// 1. 所有新增数据必须以 [qaPrefix] 开头，便于识别、统计与清理；
/// 2. 名称拼接 [qaRunId]，避免与历史残留或并发任务混淆；
/// 3. 空态断言统一搜索 [qaEmptyKeyword]，不依赖面板默认是否为空；
/// 4. 新增数据一律在 addTearDown/finally 中清理，成功失败都执行。
const String qaPrefix = 'qa_ui_';
const String qaEmptyKeyword = 'qa_ui_empty_probe';
const String qaDefaultHost = 'http://demo.qinglong.online:4433';

/// 本次运行标识（同一次测试内保持一致）
String qaRunId() => '${DateTime.now().millisecondsSinceEpoch % 1000000}';

String qaHost() => Platform.environment['QL_HOST'] ?? qaDefaultHost;

Future<Map<String, dynamic>> qaApi(
  String method,
  String path, {
  Object? body,
  String? token,
}) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.openUrl(
      method,
      Uri.parse(qaHost() + path),
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

Future<String?> qaLogin() async {
  final Map<String, dynamic> login = await qaApi(
    "POST",
    "/api/user/login",
    body: {
      "username": Platform.environment["QL_USER"] ?? "admin",
      "password": Platform.environment["QL_PASS"] ?? "123",
    },
  );
  final String? token = (login["data"] as Map?)?["token"]?.toString();
  return (token == null || token.isEmpty) ? null : token;
}
