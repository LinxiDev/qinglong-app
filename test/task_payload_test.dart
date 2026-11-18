import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/module/task/task_payload.dart';

void main() {
  group('buildTaskPayload', () {
    test('包含 v2.25 新增字段', () {
      final Map<String, dynamic> payload = buildTaskPayload(
        name: '每日签到',
        command: 'task sign.py',
        schedule: '0 8 * * *',
        allowMultipleInstances: 1,
        workDir: '/ql/scripts',
        logName: 'sign.log',
        taskBefore: 'node check.js',
        taskAfter: 'python notify.py',
        extraSchedules: <String>['30 9 * * *', '0 12 * * *'],
        skipIfPending: true,
        maxQueueWait: 120,
        catchupSeconds: 60,
      );

      expect(payload['name'], '每日签到');
      expect(payload['command'], 'task sign.py');
      expect(payload['schedule'], '0 8 * * *');
      expect(payload['allow_multiple_instances'], 1);
      expect(payload['work_dir'], '/ql/scripts');
      expect(payload['log_name'], 'sign.log');
      expect(payload['task_before'], 'node check.js');
      expect(payload['task_after'], 'python notify.py');
      expect(payload['skip_if_pending'], true);
      expect(payload['max_queue_wait'], 120);
      expect(payload['catchup_seconds'], 60);
      expect(payload['extra_schedules'], <Map<String, String>>[
        <String, String>{'schedule': '30 9 * * *'},
        <String, String>{'schedule': '0 12 * * *'},
      ]);
    });

    test('非 cron 定时（manual/on_boot）不发送额外规则与排队字段', () {
      final Map<String, dynamic> payload = buildTaskPayload(
        name: '开机自检',
        command: 'check.sh',
        schedule: 'on_boot',
        allowMultipleInstances: 0,
        includeExtraSchedules: false,
      );

      expect(payload['schedule'], 'on_boot');
      expect(payload.containsKey('extra_schedules'), isFalse);
      expect(payload.containsKey('skip_if_pending'), isFalse);
      expect(payload.containsKey('max_queue_wait'), isFalse);
      expect(payload.containsKey('catchup_seconds'), isFalse);
    });

    test('旧面板（不支持排队配置）不发送 skip_if_pending', () {
      final Map<String, dynamic> payload = buildTaskPayload(
        name: '旧面板任务',
        command: 'echo 1',
        schedule: '0 1 * * *',
        allowMultipleInstances: 0,
        extraSchedules: <String>['0 2 * * *'],
      );

      expect(payload.containsKey('skip_if_pending'), isFalse);
      expect(payload['extra_schedules'], <Map<String, String>>[
        <String, String>{'schedule': '0 2 * * *'},
      ]);
    });
  });
}
