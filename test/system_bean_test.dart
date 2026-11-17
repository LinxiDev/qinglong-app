import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/module/home/system_bean.dart';

void main() {
  group('SystemBean 版本解析', () {
    test('解析常规版本号', () {
      expect(SystemBean(version: "2.23.1").versionCode, 22301);
      expect(SystemBean(version: "2.9.0").versionCode, 20900);
      expect(SystemBean(version: "3.0.0").versionCode, 30000);
    });

    test('解析带预发布后缀的版本号', () {
      expect(SystemBean(version: "2.25.0-rc.1").versionCode, 22500);
      expect(SystemBean(version: "2.24.0-beta").versionCode, 22400);
    });

    test('异常版本号不抛异常', () {
      expect(SystemBean(version: null).versionCode, 0);
      expect(SystemBean(version: "").versionCode, 0);
      expect(SystemBean(version: "unknown").versionCode, 0);
    });

    test('新版本能力判断', () {
      expect(SystemBean(version: "2.22.0").isUpperVersion2_22_0(), isTrue);
      expect(SystemBean(version: "2.21.9").isUpperVersion2_22_0(), isFalse);
      expect(SystemBean(version: "2.23.0").isUpperVersion2_23_0(), isTrue);
      expect(SystemBean(version: "2.24.0").isUpperVersion2_24_0(), isTrue);
      expect(SystemBean(version: "2.23.9").isUpperVersion2_24_0(), isFalse);
    });

    test('兼容旧版本判断方法', () {
      expect(SystemBean(version: "2.14.5").isUpperVersion2_14_5(), isTrue);
      expect(SystemBean(version: "2.14.4").isUpperVersion2_14_5(), isFalse);
      expect(SystemBean(version: "2.13.9").isUpperVersion2_13_9(), isTrue);
      expect(SystemBean(version: "2.12.2").isUpperVersion2_12_2(), isTrue);
      expect(SystemBean(version: "2.10.13").isUpperVersion(), isFalse);
    });
  });
}
