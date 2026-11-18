import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:qinglong_app/base/base_viewmodel.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/module/others/dependencies/dependency_bean.dart';
import 'package:qinglong_app/module/others/dependencies/dependency_page.dart';
import 'package:qinglong_app/utils/extension.dart';

class DependencyViewModel extends BaseViewModel {
  List<DependencyBean> nodeJsList = [];
  List<DependencyBean> python3List = [];
  List<DependencyBean> linuxList = [];

  @override
  void retry(BuildContext context, {bool showLoading = true}) async {
    await loadData(
      context,
      DepedencyEnum.nodeJs.name.toLowerCase().toString(),
      true,
    );
    if (context.mounted) {
      await loadData(
        context,
        DepedencyEnum.python3.name.toLowerCase().toString(),
        true,
      );
    }
    if (context.mounted) {
      await loadData(
        context,
        DepedencyEnum.linux.name.toLowerCase().toString(),
        true,
      );
    }
  }

  List<DependencyBean> getListByType(int index) {
    if (DependcyPageState.types[index].name ==
        DepedencyEnum.nodeJs.name.toString()) {
      return nodeJsList;
    } else if (DependcyPageState.types[index].name ==
        DepedencyEnum.python3.name.toString()) {
      return python3List;
    }
    return linuxList;
  }

  Future<void> loadData(
    BuildContext context,
    String type, [
    bool showLoading = false,
  ]) async {
    type = type.toLowerCase();
    if (showLoading &&
        ((type == "nodejs" && nodeJsList.isEmpty) ||
            (type == "python3" && python3List.isEmpty) ||
            (type == "linux" && linuxList.isEmpty))) {
      loading(notify: true);
    }

    HttpResponse<List<DependencyBean>> response =
        await SingleAccountPageState.ofApi(context).dependencies(type);
    if (response.success) {
      if (type == "nodejs") {
        nodeJsList.clear();
        nodeJsList.addAll(response.bean!);
      }
      if (type == "python3") {
        python3List.clear();
        python3List.addAll(response.bean!);
      }
      if (type == "linux") {
        linuxList.clear();
        linuxList.addAll(response.bean!);
      }
      success();
    } else {
      response.message?.toast();
    }
  }

  void reInstall(
    BuildContext context,
    String type,
    List<String?>? sId,
    List<int?>? id,
  ) async {
    await SingleAccountPageState.ofApi(context).dependencyReinstall(sId, id);
    if (context.mounted) {
      await loadData(context, type);
    }
  }

  Future<void> del(
    BuildContext context,
    String type,
    List<String?>? sId,
    List<int?>? ids,
  ) async {
    await SingleAccountPageState.ofApi(context).delDependency(sId, ids);
  }
}

enum DepedencyEnum { nodeJs, python3, linux }
