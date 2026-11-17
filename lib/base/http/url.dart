import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';

class Url {
  int index;

  Url(this.index);

  static get login => "/api/user/login";

  static get system => "/api/system";

  static get loginOld => "/api/login";

  static get loginTwo => "/api/user/two-factor/login";
  static const loginByClientId = "/open/auth/token";
  static const user = "/api/user";

  static const updatePassword = "/api/user";

  get logDel => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/system/log/remove" : "/api/system/log/remove";

  get tasks => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons" : "/api/crons";

  get subscribes => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions" : "/api/subscriptions";

  get notifcations => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/user/notification" : "/api/user/notification";

  get runSubscribes => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions/run" : "/api/subscriptions/run";

  get stopSubscribes => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions/stop" : "/api/subscriptions/stop";

  get addSubscribes => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions" : "/api/subscriptions";

  get enableSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions/enable" : "/api/subscriptions/enable";

  get disableSubscribes =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions/disable" : "/api/subscriptions/disable";

  get runTasks => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/run" : "/api/crons/run";

  get stopTasks => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/stop" : "/api/crons/stop";

  get taskDetail => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/" : "/api/crons/";

  get addTask => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons" : "/api/crons";

  get pinTask => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/pin" : "/api/crons/pin";

  get unpinTask => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/unpin" : "/api/crons/unpin";

  get enableTask => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/enable" : "/api/crons/enable";

  get disableTask => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/disable" : "/api/crons/disable";

  get files => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/configs/files" : "/api/configs/files";

  get configContent => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/configs/" : "/api/configs/";

  get saveFile => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/configs/save" : "/api/configs/save";

  get envs => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/envs" : "/api/envs";

  get addEnv => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/envs" : "/api/envs";

  get delEnv => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/envs" : "/api/envs";

  get disableEnvs => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/envs/disable" : "/api/envs/disable";

  get enableEnvs => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/envs/enable" : "/api/envs/enable";

  get loginLog => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/user/login-log" : "/api/user/login-log";

  get logFoldDelete => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/logs" : "/api/logs";

  get taskLog => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/logs" : "/api/logs";

  get taskLogDetail => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/logs/" : "/api/logs/";

  get scripts => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/scripts/files" : "/api/scripts/files";

  get scripts2 => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/scripts" : "/api/scripts";

  get scriptUpdate => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/scripts" : "/api/scripts";

  get scriptDetail => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/scripts" : "/api/scripts";
  get scriptDetailForReadFile => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/scripts/detail" : "/api/scripts/detail";

  get dependencies => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/dependencies" : "/api/dependencies";

  get dependenciesDeleteFocus =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/dependencies/force" : "/api/dependencies/force";

  get dependenciesReinstall =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/dependencies/reinstall" : "/api/dependencies/reinstall";

  get addScript => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/scripts" : "/api/scripts";

  get dependencyReinstall =>
      getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/dependencies/reinstall" : "/api/dependencies/reinstall";

  get checkUpdate => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/system/update-check" : "/api/system/update-check";

  get appkeys => getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/apps" : "/api/apps";

  resetAppKey(dynamic id) {
    return getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined
        ? "/api/apps/${id.toString()}/reset-secret"
        : "/api/apps/${id.toString()}/reset-secret";
  }

  intimeLog(String cronId) {
    return getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/crons/$cronId/log" : "/api/crons/$cronId/log";
  }

  intimeDepLog(String id) {
    return getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/dependencies/$id" : "/api/dependencies/$id";
  }

  intimeSubscribeLog(int cronId) {
    return getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/subscriptions/$cronId/log" : "/api/subscriptions/$cronId/log";
  }

  envMove(String envId) {
    return getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open/envs/$envId/move" : "/api/envs/$envId/move";
  }

  /// 根据登录方式自动拼接 /api 或 /open 前缀
  String p(String path) {
    return getIt<UserInfoViewModel>(instanceName: index.toString()).useSecretLogined ? "/open$path" : "/api$path";
  }

  // ---------------- 脚本（v2.23+ 新增运行/停止/重命名/历史版本） ----------------
  get scriptsRun => p("/scripts/run");

  get scriptsStop => p("/scripts/stop");

  get scriptsRename => p("/scripts/rename");

  get scriptsHistory => p("/scripts/history");

  get scriptsHistoryDetail => p("/scripts/history/detail");

  get scriptsHistoryRestore => p("/scripts/history/restore");

  // ---------------- 定时任务（v2.22+ 新增预览/实例/触发历史） ----------------
  get cronPreview => p("/crons/preview");

  get cronDetail => p("/crons/detail");

  get cronStatus => p("/crons/status");

  get cronImport => p("/crons/import");

  String cronInstances(String id) => p("/crons/$id/instances");

  String cronTriggers(String id) => p("/crons/$id/triggers");

  String cronDailyResults(String id) => p("/crons/$id/daily-results");

  String cronInstanceStop(String id, String instanceId) => p("/crons/$id/instances/$instanceId/stop");

  String cronLogs(String id) => p("/crons/$id/logs");

  String cronDetailById(String id) => p("/crons/$id");

  // ---------------- 仪表盘统计 ----------------
  get dashboardOverview => p("/dashboard/overview");

  get dashboardTrend => p("/dashboard/trend");

  get dashboardTopTime => p("/dashboard/top-time");

  get dashboardTopCount => p("/dashboard/top-count");

  get dashboardRuntime => p("/dashboard/runtime");

  get dashboardSuccesses => p("/dashboard/successes");

  get dashboardFailures => p("/dashboard/failures");

  // ---------------- 系统 ----------------
  // 2.23+ 下线的旧接口替代：配置文件/日志内容统一走 /detail
  get configDetail => p("/configs/detail");

  get logsDetail => p("/logs/detail");

  get systemConfig => p("/system/config");

  get systemNotifyLog => p("/system/notify-log");

  get systemLog => p("/system/log");

  get systemLogDelete => p("/system/log");

  get systemNotify => p("/system/notify");

  // ---------------- 数据保留与清理 ----------------
  get retentionConfig => p("/system/storage-retention/config");

  get retentionPreview => p("/system/storage-retention/preview");

  get retentionCleanup => p("/system/storage-retention/cleanup");

  // ---------------- 用户安全 ----------------
  get ipBlacklist => p("/user/ip-blacklist");

  // ---------------- 环境变量（置顶/重命名） ----------------
  get envPin => p("/envs/pin");

  get envUnpin => p("/envs/unpin");

  get envRename => p("/envs/name");

  // ---------------- 依赖 ----------------
  get dependencyRefresh => p("/dependencies/refresh");

  get dependencyRefreshActive => p("/dependencies/refresh/active");

  get dependencyCancel => p("/dependencies/cancel");

  static bool inWhiteList(String path) {
    if (path == login || path == loginByClientId || path == loginTwo || path == loginOld) {
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
