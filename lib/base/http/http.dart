import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:qinglong_app/base/http/token_interceptor.dart';
import 'package:qinglong_app/base/http/url.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../json.jc.dart';
import '../../main.dart';
import '../routes.dart';

class Http {
  Dio? _dio;
  bool pushedLoginPage = false;

  String host;
  int index;

  Http(this.host, this.index) {
    _init();
  }

  static const Duration _timeout = Duration(seconds: 50);

  void initDioConfig(String host) {
    _dio = Dio(
      BaseOptions(
        baseUrl: host,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        contentType: "application/json",
      ),
    );
    if (kDebugMode) {
      _dio?.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: true,
        ),
      );
    }

    _dio?.interceptors.add(TokenInterceptor(host, index));
    _dio?.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final HttpClient client = HttpClient();
        // 青龙面板常使用自签名证书，客户端需要放开校验
        client.badCertificateCallback = (
          X509Certificate cert,
          String host,
          int port,
        ) => true;
        return client;
      },
    );
  }

  void _init() {
    if (_dio == null) {
      initDioConfig(host);
    }
  }

  void clear() {
    _dio = null;
  }

  /// 读取原始 JSON 对象（用于日志分块需要的 nextOffset/total 等
  /// 与 data 同级、会被 decodeResponse 丢弃的字段）
  Future<HttpResponse<Map<String, dynamic>>> getMap(
    String uri,
    Map<String, String?>? json,
  ) async {
    try {
      _init();
      final response = await _dio!.get(uri, queryParameters: json);
      if (response.statusCode == 200 && response.data is Map) {
        return HttpResponse(
          success: true,
          code: 200,
          bean: Map<String, dynamic>.from(response.data),
        );
      }
      return HttpResponse(
        success: false,
        code: response.statusCode ?? 0,
        message: response.statusMessage,
      );
    } on DioException catch (e) {
      return exceptionHandler<Map<String, dynamic>>(e, uri);
    }
  }

  Future<HttpResponse<T>> get<T>(
    String uri,
    Map<String, String?>? json, {
    bool compute = true,
    String serializationName = "data",
  }) async {
    try {
      _init();
      var response = await _dio!.get(uri, queryParameters: json);
      return decodeResponse<T>(response, serializationName, compute);
    } on DioException catch (e) {
      return exceptionHandler<T>(e, uri);
    }
  }

  Future<HttpResponse<T>> post<T>(
    String uri,
    dynamic json, {
    bool compute = true,
    String serializationName = "data",
  }) async {
    try {
      _init();
      var response = await _dio!.post(uri, data: json);

      return decodeResponse<T>(response, serializationName, compute);
    } on DioException catch (e) {
      return exceptionHandler<T>(e, uri);
    }
  }

  Future<HttpResponse<T>> delete<T>(
    String uri,
    dynamic json, {
    bool compute = true,
    String serializationName = "data",
  }) async {
    try {
      _init();
      var response = await _dio!.delete(uri, data: json);

      return decodeResponse<T>(response, serializationName, compute);
    } on DioException catch (e) {
      return exceptionHandler<T>(e, uri);
    }
  }

  Future<HttpResponse<T>> put<T>(
    String uri,
    dynamic json, {
    bool compute = true,
    String serializationName = "data",
  }) async {
    try {
      _init();
      var response = await _dio!.put(uri, data: json);
      return decodeResponse<T>(response, serializationName, compute);
    } on DioException catch (e) {
      return exceptionHandler<T>(e, uri);
    }
  }

  void exitLogin() {
    if (!pushedLoginPage) {
      "身份已过期,请重新登录".toast();
      pushedLoginPage = true;

      getIt<UserInfoViewModel>(instanceName: index.toString())
          .exitLoginFocus(index);

      getIt<GlobalKey<NavigatorState>>(instanceName: index.toString())
          .currentState
          ?.pushNamedAndRemoveUntil(Routes.routeLogin, (route) => false);
    }
  }

  HttpResponse<T> exceptionHandler<T>(DioException e, String path) {
    try {
      logger.e(e);
      if (e.response?.statusCode == 401 && !Url.inWhiteList(path)) {
        if (!getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined) {
          exitLogin();
        }
        return HttpResponse(success: false, message: "没有该模块的访问权限", code: 401);
      }

      if (e.response != null && e.response!.data is Map) {
        // 有响应体：优先展示面板返回的 message（青龙为中文）
        final dynamic data = e.response!.data;
        return HttpResponse(
          success: false,
          message: data["message"] ?? _networkErrorMessage(e),
          code: data["code"] ?? 0,
        );
      } else {
        return HttpResponse(
          success: false,
          message: _networkErrorMessage(e),
          code: e.response?.statusCode ?? 0,
        );
      }
    } catch (e) {
      logger.e(e);
      return HttpResponse(success: false, message: "请求处理失败，请稍后重试", code: 400);
    }
  }

  /// 连接级异常的中文提示（无响应体的网络错误，
  /// 避免把 Dio/Socket 的英文原文直接透出给用户）
  String _networkErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return "连接超时，请检查网络后重试";
      case DioExceptionType.connectionError:
        return "无法连接服务器，请检查网络或面板地址";
      case DioExceptionType.badCertificate:
        return "证书校验失败，请检查面板证书配置";
      case DioExceptionType.cancel:
        return "请求已取消";
      case DioExceptionType.badResponse:
        return "服务器响应异常(${e.response?.statusCode ?? 0})";
      case DioExceptionType.unknown:
        final String raw = e.error?.toString() ?? "";
        if (raw.contains("SocketException") ||
            raw.contains("Failed host lookup") ||
            raw.contains("Connection refused") ||
            raw.contains("Network is unreachable")) {
          return "网络连接失败，请检查网络后重试";
        }
        if (raw.contains("HandshakeException")) {
          return "安全连接建立失败，请检查面板证书配置";
        }
        return "网络请求失败，请稍后重试";
    }
  }

  static HttpResponse<T> decodeResponse<T>(
    Response<dynamic> response,
    String serializationName,
    bool compute,
  ) {
    int code = 0;
    if (response.statusCode == 200) {
      /// 部分官方接口直接返回文本/文件流（配置文件内容、日志内容、
      /// 镜像源切换输出等），不是 {code,data} 包装，直接视为成功
      if (response.data is! Map) {
        final String text = response.data?.toString() ?? "";
        if (T == NullResponse) {
          return HttpResponse<T>(success: true, code: 200);
        }
        if (T == String) {
          return HttpResponse<T>(success: true, code: 200, bean: text as T);
        }
        return HttpResponse<T>(success: false, code: -1000, message: text);
      }
      try {
        if (response.data["code"] == 200) {
          if (response.data[serializationName] != null) {
            if (T == NullResponse) {
              return HttpResponse<T>(success: true, code: 200);
            }

            dynamic data = response.data[serializationName];
            T t;
            if (T == String) {
              if (data is String) {
                t = data as T;
              } else {
                t = jsonEncode(data) as T;
              }
              return HttpResponse<T>(success: true, code: 200, bean: t);
            } else {
              T bean;
              if (compute) {
                bean = DeserializeAction.invokeJson(DeserializeAction<T>(data));
              } else {
                bean = JsonConversion$Json.fromJson<T>(data);
              }
              return HttpResponse<T>(success: true, code: 200, bean: bean);
            }
          } else {
            return HttpResponse<T>(success: true, code: 200);
          }
        } else {
          return HttpResponse<T>(
            success: false,
            code: response.data["code"],
            message: response.data["message"],
          );
        }
      } catch (e) {
        logger.e(e);
        return HttpResponse<T>(
          success: false,
          code: -1000,
          message: "json解析失败",
        );
      }
    } else {
      code = response.statusCode ?? 0;
      return HttpResponse(
        success: false,
        code: code,
        message: response.statusMessage,
      );
    }
  }
}

class HttpResponse<T> {
  late bool success;
  String? message;
  late int code;
  T? bean;

  HttpResponse({
    required this.success,
    this.message,
    required this.code,
    this.bean,
  });
}

class DeserializeAction<T> {
  final dynamic json;

  DeserializeAction(this.json);

  T invoke() {
    return JsonConversion$Json.fromJson<T>(json);
  }

  static dynamic invokeJson(DeserializeAction a) => a.invoke();
}

mixin BaseBean<T> {
  T fromJson(Map<String, dynamic> json);
}

class CronBean with BaseBean<CronBean> {
  @override
  CronBean fromJson(Map<String, dynamic> json) {
    return CronBean();
  }
}

void decode<T>() async {
  compute(DeserializeAction.invokeJson, DeserializeAction<T>({}));
}

class NullResponse {}

class NotLoginException implements Exception {}
