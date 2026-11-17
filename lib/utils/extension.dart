
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

extension StringExt on String? {
  void toast() {
    if (this == null || this!.isEmpty) return;
    Fluttertoast.showToast(
      msg: this!,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
    );
  }

  void toast2() {
    if (this == null || this!.isEmpty) return;
    Fluttertoast.showToast(
      msg: this!,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
    );
  }

  void log() {
    logger.i(this);
  }
}
