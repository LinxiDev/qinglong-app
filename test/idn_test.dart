import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/utils/idn.dart';

void main() {
  group('normalizeUrlHost（IDN → punycode）', () {
    test('中文域名带 http 前缀', () {
      expect(
        normalizeUrlHost('http://www.中文.com'),
        'http://www.xn--fiq228c.com',
      );
    });

    test('中文域名带端口与路径', () {
      expect(
        normalizeUrlHost('http://abc.中文.com:5700/path'),
        'http://abc.xn--fiq228c.com:5700/path',
      );
    });

    test('纯中文域名（无协议）', () {
      expect(normalizeUrlHost('中文.com'), 'xn--fiq228c.com');
    });

    test('纯 ASCII 域名保持不变', () {
      expect(
        normalizeUrlHost('http://demo.qinglong.online:4433'),
        'http://demo.qinglong.online:4433',
      );
    });

    test('已转换的 punycode 幂等', () {
      expect(
        normalizeUrlHost('http://www.xn--fiq228c.com'),
        'http://www.xn--fiq228c.com',
      );
    });
  });
}
