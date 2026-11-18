import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

/// 仅 Android / iOS 有 fluttertoast 的原生实现
bool get _hasNativeToast {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

void _showInAppToast(String msg, {required bool long}) {
  try {
    EasyLoading.showToast(
      msg,
      duration: Duration(seconds: long ? 3 : 2),
      toastPosition: EasyLoadingToastPosition.center,
    ).catchError((Object e) {
      logger.w("应用内提示不可用: $e");
    });
  } catch (e) {
    logger.w("应用内提示不可用: $e");
  }
}

void _showToast(String msg, {required bool long}) {
  if (!_hasNativeToast) {
    _showInAppToast(msg, long: long);
    return;
  }
  try {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: long ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
    ).catchError((Object e) {
      // 插件异常时退化为应用内提示，保证用户仍能看到反馈
      logger.w("原生 toast 不可用，改用应用内提示: $e");
      _showInAppToast(msg, long: long);
      return false;
    });
  } catch (e) {
    logger.w("原生 toast 不可用，改用应用内提示: $e");
    _showInAppToast(msg, long: long);
  }
}

extension StringExt on String? {
  void toast() {
    if (this == null || this!.isEmpty) return;
    _showToast(this!, long: false);
  }

  void toast2() {
    if (this == null || this!.isEmpty) return;
    _showToast(this!, long: true);
  }

  void log() {
    logger.i(this);
  }
}
