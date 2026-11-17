// 编译冒烟测试：导入应用入口与主要页面，确保整个 widget 依赖图可编译。
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/dashboard/dashboard_page.dart';
import 'package:qinglong_app/module/others/notify_log_page.dart';
import 'package:qinglong_app/module/others/scripts/script_history_page.dart';
import 'package:qinglong_app/module/setting/ip_blacklist_page.dart';
import 'package:qinglong_app/module/setting/storage_retention_page.dart';
import 'package:qinglong_app/module/task/cron_instance_page.dart';

void main() {
  test('应用入口与新增页面均可编译', () {
    expect(QlApp, isNotNull);
    expect(MultiAccountPage, isNotNull);
    expect(DashboardPage, isNotNull);
    expect(NotifyLogPage, isNotNull);
    expect(ScriptHistoryPage, isNotNull);
    expect(CronInstancePage, isNotNull);
    expect(StorageRetentionPage, isNotNull);
    expect(IpBlacklistPage, isNotNull);

    expect(Routes.routeDashboard, "/dashboard");
    expect(Routes.routeNotifyLog, "/notifyLog");
    expect(Routes.routeStorageRetention, "/retention");
    expect(Routes.routeIpBlacklist, "/ipBlacklist");
    expect(Routes.generateRoute, isNotNull);
  });
}
