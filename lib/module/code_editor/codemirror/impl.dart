import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

/// 文件扩展名 → 语法模式 key 的中心化映射。
///
/// 仅保留 python / javascript / typescript / bash / json 五套语法规则
/// （控制包体与高亮复杂度），其余类型回落 plaintext：可正常编辑查看，
/// 只是不做高亮。新增可高亮类型：在此表加一行，并在 io.dart 的
/// `_languageModeRules` 同步加一项即可。
const Map<String, String> kFileExtensionLanguages = {
  '.js': 'javascript',
  '.mjs': 'javascript',
  '.cjs': 'javascript',
  '.jsx': 'javascript',
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.py': 'python',
  '.pyw': 'python',
  '.sh': 'bash',
  '.bash': 'bash',
  '.command': 'bash',
  '.json': 'json',
};

/// 按文件名后缀自动推导语法模式 key。
///
/// 规则：忽略大小写取最后一个后缀查表；`.env` 这类隐藏文件按整名查表；
/// Dockerfile 等无后缀文件按整名特判；其余回落 plaintext。
String languageModeForFileName(String fileName) {
  final String name = fileName.trim().toLowerCase();
  final int dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) {
    return 'plaintext';
  }
  return kFileExtensionLanguages[name.substring(dot)] ?? 'plaintext';
}

class CodeMirrorOptions {
  CodeMirrorOptions({this.mode = 'shell', this.readOnly = false}) {
    theme = (SpUtil.getInt(spThemeStyle, defValue: modeWhite) == modeDark)
        ? "3024-night"
        : "neat";
    showLineNumber = SpUtil.getBool(spShowLine, defValue: true);
  }

  late final bool showLineNumber;
  final String mode;
  late final String theme;
  final bool readOnly;

  CodeMirrorOptions copyWith({String? mode, String? theme, bool? readOnly}) {
    return CodeMirrorOptions(
      mode: mode ?? this.mode,
      readOnly: readOnly ?? this.readOnly,
    );
  }
}

class EditorController {
  EditorController({
    required this.setValue,
    required this.setOptions,
    required this.refresh,
  });

  final void Function(String val) setValue;
  final void Function(CodeMirrorOptions val) setOptions;
  final void Function() refresh;
}

abstract class CodeMirrorViewImpl extends ConsumerStatefulWidget {
  const CodeMirrorViewImpl({super.key});
}

abstract class CodeMirrorViewImplState<T extends CodeMirrorViewImpl>
    extends ConsumerState<T> {}
