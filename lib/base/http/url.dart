import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';

class Url {
  int index;

  Url(this.index);

  static String get login => "/api/user/login";

  static String get system => "/api/system";

  static String get loginOld => "/api/login";

  static String get loginTwo => "/api/user/two-factor/login";
  static const loginByClientId = "/open/auth/token";
  static const user = "/api/user";

  static const updatePassword = "/api/user";

  String get logDel =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/system/log/remove"
      : "/api/system/log/remove";

  String get tasks =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons"
      : "/api/crons";

  String get subscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/subscriptions"
      : "/api/subscriptions";

  String get notifcations =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/user/notification"
      : "/api/user/notification";

  String get runSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/subscriptions/run"
      : "/api/subscriptions/run";

  String get stopSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/subscriptions/stop"
      : "/api/subscriptions/stop";

  String get addSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/subscriptions"
      : "/api/subscriptions";

  String get enableSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/subscriptions/enable"
      : "/api/subscriptions/enable";

  String get disableSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/subscriptions/disable"
      : "/api/subscriptions/disable";

  String get runTasks =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/run"
      : "/api/crons/run";

  String get stopTasks =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/stop"
      : "/api/crons/stop";

  String get taskDetail =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/"
      : "/api/crons/";

  String get addTask =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons"
      : "/api/crons";

  String get pinTask =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/pin"
      : "/api/crons/pin";

  String get unpinTask =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/unpin"
      : "/api/crons/unpin";

  String get enableTask =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/enable"
      : "/api/crons/enable";

  String get disableTask =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/crons/disable"
      : "/api/crons/disable";

  String get files =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/configs/files"
      : "/api/configs/files";

  String get configContent =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/configs/"
      : "/api/configs/";

  String get saveFile =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/configs/save"
      : "/api/configs/save";

  String get envs =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/envs"
      : "/api/envs";

  String get addEnv =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/envs"
      : "/api/envs";

  String get delEnv =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/envs"
      : "/api/envs";

  String get disableEnvs =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/envs/disable"
      : "/api/envs/disable";

  String get enableEnvs =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/envs/enable"
      : "/api/envs/enable";

  String get loginLog =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/user/login-log"
      : "/api/user/login-log";

  String get logFoldDelete =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/logs"
      : "/api/logs";

  String get taskLog =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/logs"
      : "/api/logs";

  String get taskLogDetail =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/logs/"
      : "/api/logs/";

  String get scripts =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/scripts/files"
      : "/api/scripts/files";

  String get scripts2 =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/scripts"
      : "/api/scripts";

  String get scriptUpdate =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/scripts"
      : "/api/scripts";

  String get scriptDetail =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/scripts"
      : "/api/scripts";
  String get scriptDetailForReadFile =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/scripts/detail"
      : "/api/scripts/detail";

  String get dependencies =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/dependencies"
      : "/api/dependencies";

  String get dependenciesDeleteFocus =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/dependencies/force"
      : "/api/dependencies/force";

  String get dependenciesReinstall =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/dependencies/reinstall"
      : "/api/dependencies/reinstall";

  String get addScript =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/scripts"
      : "/api/scripts";

  String get dependencyReinstall =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/dependencies/reinstall"
      : "/api/dependencies/reinstall";

  String get checkUpdate =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/system/update-check"
      : "/api/system/update-check";

  String get appkeys =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
      ? "/open/apps"
      : "/api/apps";

  String resetAppKey(dynamic id) {
    return getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined
        ? "/api/apps/${id.toString()}/reset-secret"
        : "/api/apps/${id.toString()}/reset-secret";
  }

  String intimeLog(String cronId) {
    return getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined
        ? "/open/crons/$cronId/log"
        : "/api/crons/$cronId/log";
  }

  String intimeDepLog(String id) {
    return getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined
        ? "/open/dependencies/$id"
        : "/api/dependencies/$id";
  }

  String intimeSubscribeLog(int cronId) {
    return getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined
        ? "/open/subscriptions/$cronId/log"
        : "/api/subscriptions/$cronId/log";
  }

  String envMove(String envId) {
    return getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined
        ? "/open/envs/$envId/move"
        : "/api/envs/$envId/move";
  }

  /// 根据登录方式自动拼接 /api 或 /open 前缀
  String p(String path) {
    return getIt<UserInfoViewModel>(instanceName: index.toString())
            .useSecretLogined
        ? "/open$path"
        : "/api$path";
  }

  // ---------------- 脚本（v2.23+ 新增运行/停止/重命名/历史版本） ----------------
  String get scriptsRun => p("/scripts/run");

  String get scriptsStop => p("/scripts/stop");

  String get scriptsRename => p("/scripts/rename");

  String get scriptsHistory => p("/scripts/history");

  String get scriptsHistoryDetail => p("/scripts/history/detail");

  String get scriptsHistoryRestore => p("/scripts/history/restore");

  // ---------------- 定时任务（v2.22+ 新增预览/实例/触发历史） ----------------
  String get cronPreview => p("/crons/preview");

  String get cronDetail => p("/crons/detail");

  String get cronStatus => p("/crons/status");

  String get cronImport => p("/crons/import");

  String cronInstances(String id) => p("/crons/$id/instances");

  String cronTriggers(String id) => p("/crons/$id/triggers");

  String cronDailyResults(String id) => p("/crons/$id/daily-results");

  String cronInstanceStop(String id, String instanceId) =>
      p("/crons/$id/instances/$instanceId/stop");

  String cronLogs(String id) => p("/crons/$id/logs");

  String cronDetailById(String id) => p("/crons/$id");

  // ---------------- 仪表盘统计 ----------------
  String get dashboardOverview => p("/dashboard/overview");

  String get dashboardTrend => p("/dashboard/trend");

  String get dashboardTopTime => p("/dashboard/top-time");

  String get dashboardTopCount => p("/dashboard/top-count");

  String get dashboardRuntime => p("/dashboard/runtime");

  String get dashboardSuccesses => p("/dashboard/successes");

  String get dashboardFailures => p("/dashboard/failures");

  // ---------------- 系统 ----------------
  // 2.23+ 下线的旧接口替代：配置文件/日志内容统一走 /detail
  String get configDetail => p("/configs/detail");

  String get logsDetail => p("/logs/detail");

  String get systemConfig => p("/system/config");

  String get systemNotifyLog => p("/system/notify-log");

  String get systemLog => p("/system/log");

  String get systemLogDelete => p("/system/log");

  String get systemNotify => p("/system/notify");

  // ---------------- 数据保留与清理 ----------------
  String get retentionConfig => p("/system/storage-retention/config");

  String get retentionPreview => p("/system/storage-retention/preview");

  String get retentionCleanup => p("/system/storage-retention/cleanup");

  // ---------------- 用户安全 ----------------
  String get ipBlacklist => p("/user/ip-blacklist");

  // ---------------- 用户资料 ----------------
  /// 用户头像上传（multipart/form-data，字段名 avatar，面板 v2.24+ 支持）
  String get userAvatar => p("/user/avatar");

  // ---------------- 环境变量（置顶/重命名） ----------------
  String get envPin => p("/envs/pin");

  String get envUnpin => p("/envs/unpin");

  String get envRename => p("/envs/name");

  // ---------------- 依赖 ----------------
  String get dependencyRefresh => p("/dependencies/refresh");

  String get dependencyRefreshActive => p("/dependencies/refresh/active");

  String get dependencyCancel => p("/dependencies/cancel");

  static bool inWhiteList(String path) {
    if (path == login ||
        path == loginByClientId ||
        path == loginTwo ||
        path == loginOld) {
      return true;
    }
    return false;
  }

  static bool inLoginList(String path) {
    if (path == login || path == loginByClientId || path == loginOld) {
      return true;
    }
    return false;
  }
}
