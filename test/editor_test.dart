import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/module/code_editor/codemirror/io.dart';
import 'package:qinglong_app/module/code_editor/editor.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 回归：原生编辑器（re_editor）页面装配路径。
///
/// 页面的固定用法：onCreate 回调里 setOptions + setValue 灌入内容。
/// 编辑（readOnly: false）与只读（readOnly: true）两种模式下，
/// 控制器必须持有文本、onValue 必须回传、且构建过程不得抛异常。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String content = 'line1\nline2 abc\n# 注释行';

  Future<({EditorController? controller, String? received})> pumpEditor(
    WidgetTester tester, {
    required bool readOnly,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await SpUtil.getInstance();

    EditorController? captured;
    String? received;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Editor(
              options: CodeMirrorOptions().copyWith(readOnly: readOnly),
              onCreate: (controller) {
                captured = controller;
                controller.setOptions(
                  CodeMirrorOptions().copyWith(readOnly: readOnly),
                );
                controller.setValue(content);
              },
              onValue: (val) {
                received = val;
              },
            ),
          ),
        ),
      ),
    );
    // 首帧后 onCreate 触发
    await tester.pump();
    // textAsync 异步解析落盘
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    return (controller: captured, received: received);
  }

  testWidgets('编辑模式：onCreate 灌入内容后编辑器持有文本且无异常', (tester) async {
    final result = await pumpEditor(tester, readOnly: false);

    expect(result.controller, isNotNull, reason: 'onCreate 必须回传控制器');
    expect(
      tester.state<CodeMirrorViewState>(find.byType(CodeMirrorView)).debugText,
      content,
      reason: 'setValue 后内容必须进入编辑器渲染数据源',
    );
    // setValue 不应回声触发 onValue（对齐旧 CodeMirror 仅用户编辑才回调）
    expect(result.received, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('只读模式：同装配路径正常', (tester) async {
    final result = await pumpEditor(tester, readOnly: true);

    expect(result.controller, isNotNull);
    expect(
      tester.state<CodeMirrorViewState>(find.byType(CodeMirrorView)).debugText,
      content,
    );
    expect(tester.takeException(), isNull);
  });

  group('languageModeForFileName 按后缀自动推导', () {
    test('保留高亮的五种语言', () {
      expect(languageModeForFileName('task.py'), 'python');
      expect(languageModeForFileName('sign.js'), 'javascript');
      expect(languageModeForFileName('utils.ts'), 'typescript');
      expect(languageModeForFileName('backup.sh'), 'bash');
      expect(languageModeForFileName('data.json'), 'json');
    });

    test('未收录类型回落 plaintext（可编辑、不高亮）', () {
      expect(languageModeForFileName('config.yml'), 'plaintext');
      expect(languageModeForFileName('page.html'), 'plaintext');
      expect(languageModeForFileName('.env'), 'plaintext');
      expect(languageModeForFileName('Dockerfile'), 'plaintext');
      expect(languageModeForFileName('readme.abc'), 'plaintext');
      expect(languageModeForFileName('noext'), 'plaintext');
      expect(languageModeForFileName('.gitignore'), 'plaintext');
    });
  });
}
