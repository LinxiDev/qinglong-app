import 'dart:io';

import 'package:material_ui/material_ui.dart';



class QlVisible extends StatelessWidget {
  final Widget child;
  final Widget? childReplace;

  const QlVisible({
    super.key,
    required this.child,
    this.childReplace,
  });

  @override
  Widget build(BuildContext context) {
    if (childReplace != null && Platform.isAndroid) return childReplace!;
    return Visibility(
      visible: Platform.isIOS,
      child: child,
    );
  }
}
