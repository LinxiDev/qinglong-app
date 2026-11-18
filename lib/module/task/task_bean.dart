
import '../../main.dart';

/// 定时类型：常规定时 / 手动运行(@once) / 开机运行(@boot)
class ScheduleType {
  static const String normal = "normal";
  static const String once = "once";
  static const String boot = "boot";

  /// 从面板的 schedule 字符串推断类型
  static String of(String? schedule) {
    if (schedule == null) return normal;
    if (schedule.startsWith("@once")) return once;
    if (schedule.startsWith("@boot")) return boot;
    return normal;
  }

  /// 类型对应写入面板的 schedule 值
  static String value(String type) {
    if (type == once) return "@once";
    if (type == boot) return "@boot";
    return "";
  }

  static String label(String type) {
    if (type == once) return "手动运行";
    if (type == boot) return "开机运行";
    return "常规定时";
  }
}

class TaskBean {
  String? name;
  String? command;
  String? schedule;
  bool? saved;
  String? sId;
  int? id;
  String? _id;
  int? created;
  int? status;
  String? timestamp;
  int? isSystem;
  int? isDisabled;
  String? logPath;
  int? isPinned;
  int? lastExecutionTime;
  int? lastRunningTime;
  String? pid;
  String? updatedAt;
  String? createdAt;

  /// 额外定时规则（同一任务多条 cron）
  List<String> extraSchedules = [];

  /// 实例模式：0 单实例（运行中跳过新触发） / 1 多实例并发
  int? allowMultipleInstances;

  /// 工作目录
  String? workDir;

  /// 执行前 / 执行后命令
  String? taskBefore;
  String? taskAfter;

  /// 自定义日志文件夹名称，支持 /dev/null
  String? logName;

  /// 标签
  List<String> labels = [];

  /// 上一次仍在排队或运行时是否跳过本次
  bool? skipIfPending;

  /// 最长排队时间（秒），0 表示不限
  int? maxQueueWait;

  /// 重启后往前查找补跑的时长（秒）
  int? catchupSeconds;

  TaskBean({
    this.name,
    this.command,
    this.schedule,
    this.saved,
    this.sId,
    this.created,
    this.status,
    this.timestamp,
    this.isSystem,
    this.isDisabled,
    this.logPath,
    this.isPinned,
    this.lastExecutionTime,
    this.lastRunningTime,
    this.pid,
  });

  String? get nId => _id;

  /// 定时类型
  String get scheduleType => ScheduleType.of(schedule);

  TaskBean.fromJson(Map<String, dynamic> json) {
    try {
      name = json['name'].toString();
      command = json['command'].toString();
      schedule = json['schedule'].toString();
      saved = json['saved'];
      id = json['id'];
      _id = json['_id'];
      sId = json.containsKey('_id')
          ? json['_id'].toString()
          : (json.containsKey('id') ? json['id'].toString() : "");
      created = int.tryParse(json['created'].toString());
      status = json['status'];
      timestamp = json['timestamp'].toString();
      createdAt = json['createdAt'];
      updatedAt = json['updatedAt'];
      isSystem = json['isSystem'];
      isDisabled = json['isDisabled'];
      logPath = json['log_path'].toString();
      isPinned = json['isPinned'];
      lastExecutionTime = int.tryParse(json['last_execution_time'].toString());
      lastRunningTime = json['last_running_time'];
      pid = json['pid'].toString();

      final dynamic extra = json['extra_schedules'];
      if (extra is List) {
        extraSchedules = extra
            .map((e) => e is Map ? "${e['schedule'] ?? ''}" : "$e")
            .where((e) => e.isNotEmpty)
            .toList();
      }

      allowMultipleInstances = _toInt(json['allow_multiple_instances']);
      workDir = _toStr(json['work_dir']);
      taskBefore = _toStr(json['task_before']);
      taskAfter = _toStr(json['task_after']);
      logName = _toStr(json['log_name']);
      skipIfPending = json['skip_if_pending'] == true;
      maxQueueWait = _toInt(json['max_queue_wait']);
      catchupSeconds = _toInt(json['catchup_seconds']);

      final dynamic labelList = json['labels'];
      if (labelList is List) {
        labels = labelList.map((e) => "$e").where((e) => e.isNotEmpty).toList();
      }
    } catch (e) {
      logger.e(e);
    }
  }

  static String? _toStr(dynamic value) {
    if (value == null) return null;
    final String text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['command'] = command;
    data['schedule'] = schedule;
    data['saved'] = saved;
    data['_id'] = sId;
    data['created'] = created;
    data['status'] = status;
    data['timestamp'] = timestamp;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['isSystem'] = isSystem;
    data['isDisabled'] = isDisabled;
    data['log_path'] = logPath;
    data['isPinned'] = isPinned;
    data['last_execution_time'] = lastExecutionTime;
    data['last_running_time'] = lastRunningTime;
    data['pid'] = pid;
    return data;
  }

  static TaskBean jsonConversion(Map<String, dynamic> json) {
    return TaskBean.fromJson(json);
  }
}
