/// 极简文本差异计算（行级 LCS），用于脚本历史版本对比。
///
/// 未引入第三方 diff 依赖，避免额外体积；
/// 超大文本（超过 [maxLines]）会退化为整段替换，防止 UI 卡顿。
class DiffLine {
  /// 类型：same / add / remove
  final String type;
  final String text;

  /// 原文与新版中的行号（从 1 开始，不存在时为 null）
  final int? oldLine;
  final int? newLine;

  const DiffLine({
    required this.type,
    required this.text,
    this.oldLine,
    this.newLine,
  });
}

class DiffUtil {
  static const int maxLines = 4000;

  static List<DiffLine> diff(String oldText, String newText) {
    final List<String> a = oldText.split("\n");
    final List<String> b = newText.split("\n");

    if (a.length > maxLines || b.length > maxLines) {
      return [
        ...a.map((e) => DiffLine(type: "remove", text: e)),
        ...b.map((e) => DiffLine(type: "add", text: e)),
      ];
    }

    // LCS 动态规划
    final List<List<int>> dp = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );

    for (int i = a.length - 1; i >= 0; i--) {
      for (int j = b.length - 1; j >= 0; j--) {
        if (a[i] == b[j]) {
          dp[i][j] = dp[i + 1][j + 1] + 1;
        } else {
          dp[i][j] = dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
        }
      }
    }

    final List<DiffLine> result = [];
    int i = 0;
    int j = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        result.add(
          DiffLine(type: "same", text: a[i], oldLine: i + 1, newLine: j + 1),
        );
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        result.add(DiffLine(type: "remove", text: a[i], oldLine: i + 1));
        i++;
      } else {
        result.add(DiffLine(type: "add", text: b[j], newLine: j + 1));
        j++;
      }
    }
    while (i < a.length) {
      result.add(DiffLine(type: "remove", text: a[i], oldLine: i + 1));
      i++;
    }
    while (j < b.length) {
      result.add(DiffLine(type: "add", text: b[j], newLine: j + 1));
      j++;
    }

    return result;
  }

  /// 统计新增 / 删除行数
  static Map<String, int> stat(List<DiffLine> lines) {
    int add = 0;
    int remove = 0;
    for (final line in lines) {
      if (line.type == "add") add++;
      if (line.type == "remove") remove++;
    }
    return {"add": add, "remove": remove};
  }
}
