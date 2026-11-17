import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/utils/diff_util.dart';

void main() {
  group('DiffUtil 行级差异', () {
    test('内容一致时全部为 same', () {
      final lines = DiffUtil.diff("a\nb\nc", "a\nb\nc");
      expect(lines.length, 3);
      expect(lines.every((e) => e.type == "same"), isTrue);
      expect(DiffUtil.stat(lines), {"add": 0, "remove": 0});
    });

    test('新增一行', () {
      final lines = DiffUtil.diff("a\nc", "a\nb\nc");
      final stat = DiffUtil.stat(lines);
      expect(stat["add"], 1);
      expect(stat["remove"], 0);
      expect(lines.any((e) => e.type == "add" && e.text == "b"), isTrue);
    });

    test('删除一行', () {
      final lines = DiffUtil.diff("a\nb\nc", "a\nc");
      final stat = DiffUtil.stat(lines);
      expect(stat["remove"], 1);
      expect(stat["add"], 0);
    });

    test('修改一行会产生一增一删', () {
      final lines = DiffUtil.diff("a\nb", "a\nB");
      final stat = DiffUtil.stat(lines);
      expect(stat["add"], 1);
      expect(stat["remove"], 1);
    });

    test('保留原文与新文行号', () {
      final lines = DiffUtil.diff("a\nb", "a\nb\nc");
      final same = lines.firstWhere((e) => e.type == "same" && e.text == "b");
      expect(same.oldLine, 2);
      expect(same.newLine, 2);
    });
  });
}
