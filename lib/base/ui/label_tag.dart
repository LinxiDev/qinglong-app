import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// 环境变量标签，对齐青龙官方前端的 Ant Design Tag 观感：
/// 蓝色系、圆角 4、12 号字，可选的关闭按钮。
class LabelTag extends ConsumerWidget {
  final String title;
  final VoidCallback? onRemove;

  const LabelTag(this.title, {super.key, this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final Color blue = dark ? const Color(0xff69B1FF) : const Color(0xff1677FF);
    final Color background = dark
        ? const Color(0xff1677FF).withValues(alpha: 0.18)
        : const Color(0xffE6F4FF);
    final Color border = dark
        ? const Color(0xff1677FF).withValues(alpha: 0.50)
        : const Color(0xff91CAFF);

    return Container(
      height: 24,
      padding: EdgeInsets.only(left: 7, right: onRemove == null ? 7 : 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: blue, height: 1.0)),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 13,
                color: blue.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
