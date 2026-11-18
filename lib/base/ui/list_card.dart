import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// 统一的列表卡片样式。
///
/// 浅色 / 暗色下都有可见的描边和圆角，替换原先「白底 + 白色分割线」的平板列表，
/// 用于一行一个条目的场景（配置文件、订阅、密钥等）。
class QlListCard extends ConsumerWidget {
  const QlListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onDoubleTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color background = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color borderColor = dark
        ? const Color(0xFF2E2E31)
        : const Color(0xFFE6E8EC);

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: dark
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: themeColor.titleColor(),
                          ),
                        ),
                        if (subtitle != null &&
                            subtitle!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeColor.descColor(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ??
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 16,
                        color: themeColor.hintColor(),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 列表卡片左侧的圆角图标块
class QlListCardLeading extends ConsumerWidget {
  const QlListCardLeading({
    super.key,
    required this.icon,
    this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final Color primary = color ?? ref.watch(themeProvider).primaryColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: dark ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.52, color: primary),
    );
  }
}
