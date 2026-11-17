
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

extension StringExt on String? {
  void toast() {
    if (this == null || this!.isEmpty) return;
    try {
      Fluttertoast.showToast(
        msg: this!,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
      ).catchError((Object e) {
        logger.w("toast 不可用: $e");
        return false;
      });
    } catch (e) {
      // 部分平台（桌面/Web）没有 toast 插件，避免抛出未捕获异常
      logger.w("toast 不可用: $e");
    }
  }

  void toast2() {
    if (this == null || this!.isEmpty) return;
    try {
      Fluttertoast.showToast(
        msg: this!,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
      ).catchError((Object e) {
        logger.w("toast 不可用: $e");
        return false;
      });
    } catch (e) {
      logger.w("toast 不可用: $e");
    }
  }

  void log() {
    logger.i(this);
  }
}
