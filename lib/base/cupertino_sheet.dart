import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';

/// 「更多」菜单条目。
///
/// [icon] 可选；[destructive] 为 true 时文字显示为红色（如删除类操作）。
class CupertinoSheer extends ConsumerWidget {
  final String title;
  final GestureTapCallback onTap;
  final IconData? icon;
  final bool destructive;

  const CupertinoSheer({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context, ref) {
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color foreground = destructive
        ? const Color(0xFFEA4D3E)
        : themeColor.titleColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: 20,
                    color: foreground.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: foreground, fontSize: 15.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 菜单条目之间的细分隔线
Widget addDivider() {
  return Consumer(
    builder: (context, ref, _) {
      final bool dark = ref.watch(themeProvider).themeMode == modeDark;
      return Divider(
        height: 0.5,
        thickness: 0.5,
        indent: 18,
        endIndent: 18,
        color: dark ? const Color(0xFF2E2E31) : const Color(0xFFECEEF1),
      );
    },
  );
}

/// 统一的「更多」底部菜单：圆角卡片 + 标题 + 分组条目 + 独立取消按钮。
void showMoreOperate(BuildContext context, List<Widget> list) {
  showCupertinoModalPopup(
    useRootNavigator: false,
    context: context,
    builder: (context1) {
      return Consumer(
        builder: (context, ref, _) {
          final bool dark = ref.watch(themeProvider).themeMode == modeDark;
          final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
          final Color sheetBg = dark ? const Color(0xFF232326) : Colors.white;
          final Color borderColor = dark
              ? const Color(0xFF2E2E31)
              : const Color(0xFFE6E8EC);
          final Color descColor = dark
              ? const Color(0xFF9D9DA2)
              : const Color(0xFF8A8F99);

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: sheetBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: <Widget>[
                                const SizedBox(height: 8),
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: descColor.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "更多操作",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: descColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          ...list,
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context1).pop(),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          "取消",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeColor.titleColor(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
