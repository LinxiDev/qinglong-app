class SystemBean {
  String? version;
  bool? fromAutoGet = true;

  SystemBean({this.version, this.fromAutoGet});

  SystemBean.fromJson(Map<String, dynamic> json) {
    version = json['version'];
  }

  /// 将版本号转换为可比较的数字，例如 `2.23.1` -> 22301，`2.25.0-rc.1` -> 22500。
  int get versionCode {
    try {
      final String raw = (version ?? "").trim();
      if (raw.isEmpty) return 0;
      final List<String> parts = raw.split(".");
      int major = int.tryParse(_digits(parts.isNotEmpty ? parts[0] : "")) ?? 0;
      int minor = int.tryParse(_digits(parts.length > 1 ? parts[1] : "")) ?? 0;
      int patch = int.tryParse(_digits(parts.length > 2 ? parts[2] : "")) ?? 0;
      if (major < 0) major = 0;
      if (minor < 0) minor = 0;
      if (patch < 0) patch = 0;
      return major * 10000 + minor * 100 + patch;
    } catch (e) {
      return 0;
    }
  }

  static String _digits(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int code in input.codeUnits) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(code);
      } else {
        break;
      }
    }
    return buffer.isEmpty ? "0" : buffer.toString();
  }

  bool isAtLeast(int code) => versionCode >= code;

  // 2.12.2 以及以上版本,日志从 dirs 换成了 data
  bool isUpperVersion2_12_2() => isAtLeast(21202);

  // 2.13.0 以及以上版本日志详情接口参数有变化
  bool isUpperVersion2_13_0() => isAtLeast(21300);

  // 2.13.9 以及以上版本,任务列表 api 变化
  bool isUpperVersion2_13_9() => isAtLeast(21309);

  // 2.14.0 以及以上版本列表不用排序
  bool isUpperVersion2_14_0() => isAtLeast(21400);

  // 2.14.5 以及以上版本日志/脚本可以删除
  bool isUpperVersion2_14_5() => isAtLeast(21405);

  // 2.22.0 以及以上版本支持运行概览、任务实例、数据保留
  bool isUpperVersion2_22_0() => isAtLeast(22200);

  // 2.23.0 以及以上版本支持脚本历史版本
  bool isUpperVersion2_23_0() => isAtLeast(22300);

  // 2.24.0 以及以上版本支持通知审计日志
  bool isUpperVersion2_24_0() => isAtLeast(22400);

  /// 2.10.13 以上版本,针对任务,环境变量编辑做了修改
  bool isUpperVersion() => versionCode > 21013;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['version'] = version;
    return data;
  }

  static SystemBean jsonConversion(Map<String, dynamic> json) {
    return SystemBean.fromJson(json);
  }
}
