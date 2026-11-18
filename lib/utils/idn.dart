/// 国际化域名（IDN）支持：把中文等非 ASCII 域名转换为 Punycode（xn--）形式。
///
/// Dart 的 HTTP 栈不会自动做 IDNA 转换，直接使用中文域名会解析失败，
/// 因此在把 host 交给 Dio 之前统一走 [normalizeUrlHost]。
library;

/// 判断标签是否需要 punycode 转换
bool _needsPunycode(String label) => label.runes.any((int c) => c > 0x7F);

/// RFC 3492 Punycode 编码单个标签（不含 xn-- 前缀）
String _punycodeEncode(String input) {
  // Punycode 数字表：0-25 → a-z，26-35 → 0-9
  const String baseChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const int base = 36, tmin = 1, tmax = 26, skew = 38, damp = 700;
  const int initialBias = 72, initialN = 128;

  int n = initialN, delta = 0, bias = initialBias;
  final List<int> codePoints = input.runes.toList();
  final StringBuffer output = StringBuffer();

  final List<int> basic = codePoints.where((int c) => c < 0x80).toList();
  for (final int c in basic) {
    output.writeCharCode(c);
  }
  final int handled = basic.length;
  if (handled > 0) {
    output.writeCharCode(0x2D); // '-'
  }

  int h = handled;
  while (h < codePoints.length) {
    int m = 0x10FFFF;
    for (final int c in codePoints) {
      if (c >= n && c < m) {
        m = c;
      }
    }
    delta += (m - n) * (h + 1);
    n = m;
    for (final int c in codePoints) {
      if (c < n) {
        delta++;
        continue;
      }
      if (c == n) {
        int q = delta;
        int k = base;
        while (true) {
          final int t = (k - bias) < tmin
              ? tmin
              : ((k - bias) > tmax ? tmax : (k - bias));
          if (q < t) {
            break;
          }
          output.write(baseChars[t + ((q - t) % (base - t))]);
          q = (q - t) ~/ (base - t);
          k += base;
        }
        output.write(baseChars[q]);
        // adapt
        delta = (h == handled) ? delta ~/ damp : delta ~/ 2;
        delta += delta ~/ (h + 1);
        int kk = 0;
        while (delta > ((base - tmin) * (tmax - tmin)) ~/ 2) {
          delta ~/= (base - tmin);
          kk += base;
        }
        bias = kk + (((base - tmin + 1) * delta) ~/ (delta + skew));
        delta = 0;
        h++;
      }
    }
    delta++;
    n++;
  }
  return output.toString();
}

/// 把 URL 里的主机名归一化为 ASCII（IDN → xn-- punycode）。
///
/// 兼容 `http(s)://host[:port][/path]` 与纯域名两种输入，
/// 其余部分（端口、路径）原样保留。
String normalizeUrlHost(String raw) {
  String text = raw.trim();
  if (text.isEmpty) {
    return text;
  }

  final RegExp schemeRe = RegExp(r'^(https?://)(.+)$', caseSensitive: false);
  String scheme = '';
  String rest = text;
  final RegExpMatch? schemeMatch = schemeRe.firstMatch(text);
  if (schemeMatch != null) {
    scheme = schemeMatch.group(1)!;
    rest = schemeMatch.group(2)!;
  }

  // 分离 path（第一个 / 之后）
  String hostPart = rest;
  String pathPart = '';
  final int slashIndex = rest.indexOf('/');
  if (slashIndex >= 0) {
    hostPart = rest.substring(0, slashIndex);
    pathPart = rest.substring(slashIndex);
  }

  // 分离端口
  String port = '';
  final RegExp portRe = RegExp(r'^(.*?):(\d+)$');
  final RegExpMatch? portMatch = portRe.firstMatch(hostPart);
  if (portMatch != null) {
    hostPart = portMatch.group(1)!;
    port = ':${portMatch.group(2)!}';
  }

  if (!_needsPunycode(hostPart)) {
    return text;
  }

  final StringBuffer asciiHost = StringBuffer();
  for (final String label in hostPart.split('.')) {
    if (asciiHost.isNotEmpty) {
      asciiHost.write('.');
    }
    if (_needsPunycode(label)) {
      asciiHost.write('xn--${_punycodeEncode(label)}');
    } else {
      asciiHost.write(label);
    }
  }

  return '$scheme$asciiHost$port$pathPart';
}
