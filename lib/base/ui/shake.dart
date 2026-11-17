import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// 轻量抖动动画组件（替代已停止维护的 flutter_animator）。
///
/// 通过 [ShakeWidgetState.forward] 触发一次左右抖动，
/// 常用于登录失败等需要给出负反馈的场景。
class ShakeWidget extends StatefulWidget {
  final Widget child;

  /// 抖动幅度（像素）
  final double offset;

  /// 抖动次数
  final int count;

  /// 单次抖动时长
  final Duration duration;

  const ShakeWidget({
    super.key,
    required this.child,
    this.offset = 12,
    this.count = 3,
    this.duration = const Duration(milliseconds: 90),
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> forward() async {
    for (int i = 0; i < widget.count; i++) {
      await _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final double dx =
            math.sin(progress * math.pi * 2) * widget.offset * (1 - progress);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
