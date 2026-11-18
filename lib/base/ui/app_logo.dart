import 'package:material_ui/material_ui.dart';

/// 应用 Logo，自动根据亮色/暗色主题切换配色版本。
///
/// 亮色主题使用品牌绿，暗色主题使用白色剪影，避免深色背景下看不清。
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({super.key, this.width, this.height, this.fit = BoxFit.contain});

  /// 当前主题下应使用的 Logo 资源
  static String assetOf(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? "assets/images/ql_dark.png" : "assets/images/ql.png";
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetOf(context),
      width: width,
      height: height,
      fit: fit,
    );
  }
}
