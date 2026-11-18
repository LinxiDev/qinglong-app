/// 任务新增 / 编辑的请求体构造。
///
/// 单独抽出来便于单测：面板 v2.25 新增的多实例、额外定时规则、排队策略等字段
/// 一旦在 UI 到请求体之间丢失，会在测试里直接暴露。
Map<String, dynamic> buildTaskPayload({
  required String name,
  required String command,
  required String schedule,
  required int allowMultipleInstances,
  String workDir = "",
  String logName = "",
  String taskBefore = "",
  String taskAfter = "",
  bool includeExtraSchedules = true,
  List<String> extraSchedules = const <String>[],
  bool? skipIfPending,
  int maxQueueWait = 0,
  int catchupSeconds = 0,
}) {
  final Map<String, dynamic> payload = <String, dynamic>{
    "name": name,
    "command": command,
    "schedule": schedule,
    "allow_multiple_instances": allowMultipleInstances,
    "work_dir": workDir,
    "log_name": logName,
    "task_before": taskBefore,
    "task_after": taskAfter,
  };

  if (includeExtraSchedules) {
    payload["extra_schedules"] = extraSchedules
        .map((e) => <String, dynamic>{"schedule": e})
        .toList();
  }

  if (skipIfPending != null) {
    payload["skip_if_pending"] = skipIfPending;
    payload["max_queue_wait"] = maxQueueWait;
    payload["catchup_seconds"] = catchupSeconds;
  }

  return payload;
}
