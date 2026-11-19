import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';

/// 队列中标记（官方 status=3），固定蓝色
class QueueWidget extends ConsumerWidget {
  const QueueWidget({super.key});

  @override
  Widget build(BuildContext context, ref) {
    const Color color = Color(0xff1E88E5);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingWidget(color: color, size: 12),
          const SizedBox(width: 3),
          const Text("队列中", style: TextStyle(color: color, fontSize: 9)),
        ],
      ),
    );
  }
}

class RunningWidget extends ConsumerWidget {
  const RunningWidget({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(themeProvider).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: ref.watch(themeProvider).primaryColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingWidget(color: ref.watch(themeProvider).primaryColor, size: 12),
          const SizedBox(width: 3),
          Text(
            "运行中",
            style: TextStyle(
              color: ref.watch(themeProvider).primaryColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
