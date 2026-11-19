import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:qinglong_app/base/base_viewmodel.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/module/task/task_bean.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../main.dart';

Map<int, int> sort = {0: 0, 5: 1, 3: 2, 1: 3, 4: 4};

class TaskViewModel extends BaseViewModel {
  static const String allStr = "全部";
  static const String runningStr = "运行中";
  static const String neverStr = "未使用";
  static const String notScriptStr = "拉库";
  static const String disableStr = "已禁用";

  List<TaskBean> list = [];
  List<TaskBean> running = [];
  List<TaskBean> neverRunning = [];
  List<TaskBean> notScripts = [];
  List<TaskBean> disabled = [];

  @override
  void retry(BuildContext context, {bool showLoading = true}) {
    loadData(context, showLoading);
  }

  bool runAllTasked = false;

  /// 分页与视图筛选（对齐官方 GET /crons?page&size&searchValue&filters）
  static const int pageSize = 100;
  int page = 1;
  bool hasMore = true;
  bool loadingMore = false;
  String lastSearch = "";

  Future<void> loadData(
    BuildContext context, [
    isLoading = true,
    String? search,
  ]) async {
    if (search != null) {
      lastSearch = search;
    }
    // 生命周期回调可能在注册表未就绪时到达（测试 teardown、登出瞬间等）
    final int accountIndex = SingleAccountPageState.of(context)?.index ?? 0;
    if (!getIt.isRegistered<SystemBean>(
      instanceName: accountIndex.toString(),
    )) {
      return;
    }
    if (isLoading && list.isEmpty) {
      loading(notify: true);
    }

    if (getIt<SystemBean>(
      instanceName: (SingleAccountPageState.of(context)?.index ?? 0).toString(),
    ).isUpperVersion2_13_9()) {
      var temp = await SingleAccountPageState.ofApi(context)
          .crons2_13_09(page: 1, size: pageSize, search: lastSearch);
      if (temp.success && temp.bean != null) {
        list.clear();
        list.addAll(temp.bean?.data ?? []);
        page = 1;
        hasMore = (temp.bean?.data?.length ?? 0) >= pageSize;
        if (context.mounted) {
          sortList(context);
        }
        list.isEmpty ? empty(notify: true) : success();
        if (MultiAccountPageState.actionRunAll ==
                MultiAccountPageState.useAction() &&
            !runAllTasked) {
          runAllTasked = true;
          if (context.mounted) {
            runAllTasks(context);
          }
        }
      } else {
        list.clear();
        failed(temp.message, notify: true);
      }
    } else {
      HttpResponse<List<TaskBean>> result = await SingleAccountPageState.ofApi(
        context,
      ).crons();
      if (result.success && result.bean != null) {
        list.clear();
        list.addAll(result.bean!);
        hasMore = false;
        if (context.mounted) {
          sortList(context);
        }
        list.isEmpty ? empty(notify: true) : success();
        if (MultiAccountPageState.actionRunAll ==
                MultiAccountPageState.useAction() &&
            !runAllTasked) {
          runAllTasked = true;
          if (context.mounted) {
            runAllTasks(context);
          }
        }
      } else {
        list.clear();
        failed(result.message, notify: true);
      }
    }
  }

  /// 加载下一页（列表滚动到底部时触发）
  Future<void> loadMore(BuildContext context) async {
    if (loadingMore || !hasMore) {
      return;
    }
    loadingMore = true;
    final temp = await SingleAccountPageState.ofApi(context)
        .crons2_13_09(page: page + 1, size: pageSize, search: lastSearch);
    loadingMore = false;
    if (temp.success && temp.bean != null) {
      final List<TaskBean> items = temp.bean?.data ?? [];
      if (items.length < pageSize) {
        hasMore = false;
      }
      if (items.isNotEmpty) {
        page++;
        list.addAll(items);
        if (context.mounted) {
          sortList(context);
        }
      }
      success();
    } else {
      hasMore = false;
      failed(temp.message, notify: true);
    }
  }

  void sortList(BuildContext context) {
    //2.14.0之后就不需要排序
    if (!getIt<SystemBean>(
      instanceName: (SingleAccountPageState.of(context)?.index ?? 0).toString(),
    ).isUpperVersion2_14_0()) {
      List<TaskBean> p = [];
      List<TaskBean> r = [];
      List<TaskBean> d = [];
      for (int i = 0; i < list.length; i++) {
        if (list[i].isPinned == 1) {
          p.add(list.removeAt(i));
          i--;
          continue;
        }

        if (list[i].status == 0) {
          r.add(list.removeAt(i));
          i--;
          continue;
        }
        if (list[i].isDisabled == 1) {
          d.add(list.removeAt(i));
          i--;
          continue;
        }
      }

      p.sort((TaskBean a, TaskBean b) {
        bool c = DateTime.fromMillisecondsSinceEpoch(a.created ?? 0)
            .isBefore(DateTime.fromMillisecondsSinceEpoch(b.created ?? 0));
        if (c == true) {
          return 1;
        }
        return -1;
      });

      p.sort((a, b) {
        return (a.isDisabled ?? 0) - (b.isDisabled ?? 0);
      });

      p.sort((a, b) {
        if (a.status == 0 && b.status == 0) {
          bool c = DateTime.fromMillisecondsSinceEpoch(a.created ?? 0)
              .isBefore(DateTime.fromMillisecondsSinceEpoch(b.created ?? 0));
          if (c == true) {
            return 1;
          }
          return -1;
        } else {
          return (a.status ?? 0) - (b.status ?? 0);
        }
      });

      r.sort((a, b) {
        bool c = DateTime.fromMillisecondsSinceEpoch(a.created ?? 0)
            .isBefore(DateTime.fromMillisecondsSinceEpoch(b.created ?? 0));
        if (c == true) {
          return 1;
        }
        return -1;
      });

      d.sort((a, b) {
        bool c = DateTime.fromMillisecondsSinceEpoch(a.created ?? 0)
            .isBefore(DateTime.fromMillisecondsSinceEpoch(b.created ?? 0));
        if (c == true) {
          return 1;
        }
        return -1;
      });

      list.sort((a, b) {
        bool c = DateTime.fromMillisecondsSinceEpoch(a.created ?? 0)
            .isBefore(DateTime.fromMillisecondsSinceEpoch(b.created ?? 0));
        if (c == true) {
          return 1;
        }
        return -1;
      });

      list.insertAll(0, r);
      list.insertAll(0, p);
      list.addAll(d);
    }
    running.clear();
    running.addAll(list.where((element) => element.status == 0));
    neverRunning.clear();
    neverRunning.addAll(
      list.where((element) => element.lastRunningTime == null),
    );
    notScripts.clear();
    notScripts.addAll(
      list.where(
        (element) =>
            (element.command != null &&
            (element.command!.startsWith("ql repo") ||
                element.command!.startsWith("ql raw"))),
      ),
    );

    disabled.clear();
    disabled.addAll(list.where((element) => element.isDisabled == 1));
  }

  Future<void> runCrons(BuildContext context, List<String> crons) async {
    HttpResponse<NullResponse> result = await SingleAccountPageState.ofApi(
      context,
    ).startTasks(crons);
    if (result.success) {
      if (context.mounted) {
        loadData(context, false);
      }
    } else {
      failToast(result.message, notify: true);
    }
  }

  Future<void> stopCrons(BuildContext context, List<String> crons) async {
    HttpResponse<NullResponse> result = await SingleAccountPageState.ofApi(
      context,
    ).stopTasks(crons);
    if (result.success) {
      if (context.mounted) {
        loadData(context, false);
      }
    } else {
      failToast(result.message, notify: true);
    }
  }

  Future<void> delCron(BuildContext context, List<String> id) async {
    HttpResponse<NullResponse> result = await SingleAccountPageState.ofApi(
      context,
    ).delTask(id);
    if (result.success) {
      "删除成功".toast();
      if (context.mounted) {
        loadData(context, false);
      }
    } else {
      failToast(result.message, notify: true);
    }
  }

  void updateBean(BuildContext context, TaskBean result) {
    loadData(context, false);
  }

  Future<void> pinTask(
    BuildContext context,
    List<String> sId,
    int isPinned,
  ) async {
    if (isPinned == 1) {
      HttpResponse<NullResponse> response = await SingleAccountPageState.ofApi(
        context,
      ).unpinTask(sId);

      if (response.success) {
        "取消置顶成功".toast();
        if (context.mounted) {
          loadData(context, false);
        }
      } else {
        failToast(response.message, notify: true);
      }
    } else {
      HttpResponse<NullResponse> response = await SingleAccountPageState.ofApi(
        context,
      ).pinTask(sId);

      if (response.success) {
        "置顶成功".toast();
        if (context.mounted) {
          loadData(context, false);
        }
      } else {
        failToast(response.message, notify: true);
      }
    }
  }

  Future<void> enableTask(
    BuildContext context,
    List<String> sId,
    int isDisabled,
  ) async {
    if (isDisabled == 0) {
      HttpResponse<NullResponse> response = await SingleAccountPageState.ofApi(
        context,
      ).disableTask(sId);

      if (response.success) {
        "禁用成功".toast();
        if (context.mounted) {
          loadData(context, false);
        }
      } else {
        failToast(response.message, notify: true);
      }
    } else {
      HttpResponse<NullResponse> response = await SingleAccountPageState.ofApi(
        context,
      ).enableTask(sId);

      if (response.success) {
        "启用成功".toast();
        if (context.mounted) {
          loadData(context, false);
        }
      } else {
        failToast(response.message, notify: true);
      }
    }
  }

  void runAllTasks(BuildContext context) {
    // 与 loadData 同理：注册表未就绪时跳过（生命周期回调路径）
    final int accountIndex = SingleAccountPageState.of(context)?.index ?? 0;
    if (!getIt.isRegistered<SystemBean>(
      instanceName: accountIndex.toString(),
    )) {
      return;
    }
    runAllTasked = true;
    List<String> ids = list
        .where((element) => element.isDisabled != 1)
        .map((e) => e.sId ?? "")
        .toList();
    "已运行${ids.length}个任务".toast();
    runCrons(context, ids);
  }
}
