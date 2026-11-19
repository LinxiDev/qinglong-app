// ignore_for_file: file_names
import 'package:qinglong_app/module/task/task_bean.dart';

import '../../main.dart';

class TaskBean2 {
  List<TaskBean>? data;
  int? total;

  TaskBean2({this.data, this.total});

  TaskBean2.fromJson(Map<String, dynamic> json) {
    try {
      total = json['total'] is num ? (json['total'] as num).toInt() : null;
      if (json['data'] != null) {
        data = <TaskBean>[];
        json['data'].forEach((v) {
          data!.add(TaskBean.fromJson(v));
        });
      }
    } catch (e) {
      logger.e(e);
    }
  }

  static TaskBean2 jsonConversion(Map<String, dynamic> json) {
    return TaskBean2.fromJson(json);
  }
}
