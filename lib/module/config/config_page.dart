import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/base_state_widget.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/ui/empty_widget.dart';
import 'package:qinglong_app/base/ui/list_card.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/config/add_config_page.dart';
import 'package:qinglong_app/module/config/config_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'config_viewmodel.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConfigPageState createState() => ConfigPageState();
}

class ConfigPageState extends ConsumerState<ConfigPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  BuildContext? childContext;
  String? configContent;
  bool gotoConfigDetailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadConfigData(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (MultiAccountPageState.actionEditConfig ==
          MultiAccountPageState.useAction()) {
        gotoConfigDetailed = false;
        loadConfigData(context);
      }
    }
  }

  Future<void> loadConfigData(BuildContext context) async {
    HttpResponse<String> result = await SingleAccountPageState.ofApi(context)
        .content("config.sh");
    if (result.success && result.bean != null) {
      configContent = result.bean;

      if (MultiAccountPageState.actionEditConfig ==
              MultiAccountPageState.useAction() &&
          !gotoConfigDetailed) {
        gotoConfigDetailed = true;
        if (context.mounted) {
          Navigator.of(context)
              .pushNamed(
                Routes.routeConfigEdit,
                arguments: {"title": "config.sh", "content": configContent},
              )
              .then((value) {
                if (context.mounted) {
                  loadConfigData(context);
                }
              });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        canBack: false,
        title: "配置文件",
        actions: [
          CupertinoButton(
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.of(context)
                  .push(
                    CupertinoPageRoute(
                      builder: (context) => const AddConfigPage(),
                    ),
                  )
                  .then((value) {
                    if (!mounted) {
                      return;
                    }
                    if (value != null && value == true) {
                      if (context.mounted) {
                        ref
                            .read(
                              SingleAccountPageState.ofConfigProvider(context)(
                                getProviderName(context),
                              ).notifier,
                            )
                            .loadData(context, false);
                      }
                    }
                  });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Center(
                child: Icon(
                  CupertinoIcons.add,
                  size: 24,
                  color: Theme.of(context).appBarTheme.iconTheme?.color,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BaseStateWidget<ConfigViewModel>(
        builder: (ref, model, child) {
          List<Widget> list = [];
          for (int i = 0; i < model.list.length; i++) {
            ConfigBean value = model.list[i];
            final bool isMainConfig = value.title?.toLowerCase() == "config.sh";

            list.add(
              ConfigCell(
                bean: value,
                onDoubleTap: isMainConfig
                    ? () {
                        if (configContent == null) {
                          "配置内容加载中，请稍候".toast();
                          loadConfigData(context);
                          return;
                        }
                        Navigator.of(context)
                            .pushNamed(
                              Routes.routeConfigEdit,
                              arguments: {
                                "title": value.title,
                                "content": configContent,
                              },
                            )
                            .then((value) {
                              Future.delayed(const Duration(seconds: 1), () {
                                if (context.mounted) {
                                  loadConfigData(context);
                                }
                              });
                            });
                      }
                    : null,
              ),
            );
          }

          return model.list.isEmpty
              ? const EmptyWidget()
              : RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    if (!mounted) {
                      return;
                    }
                    await loadConfigData(context);
                    if (context.mounted) {
                      return model.loadData(context, false);
                    }
                  },
                  child: ListView(
                    primary: true,
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: kBottomNavigationBarHeight + 50,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: list,
                  ),
                );
        },
        model: SingleAccountPageState.ofConfigProvider(context)(
          getProviderName(context),
        ),
        onReady: (viewModel) {
          viewModel.loadData(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ConfigCell extends ConsumerWidget {
  final ConfigBean bean;
  final VoidCallback? onDoubleTap;

  const ConfigCell({super.key, required this.bean, this.onDoubleTap});

  static String _fileKind(String? name) {
    final String lower = (name ?? "").toLowerCase();
    if (lower.endsWith(".sh")) return "Shell 脚本";
    if (lower.endsWith(".js")) return "JavaScript";
    if (lower.endsWith(".py")) return "Python";
    if (lower.endsWith(".json")) return "JSON";
    if (lower.endsWith(".yaml") || lower.endsWith(".yml")) return "YAML";
    if (lower.endsWith(".conf") || lower.endsWith(".ini")) return "配置文件";
    return "文件";
  }

  @override
  Widget build(BuildContext context, ref) {
    final bool isMainConfig = bean.title?.toLowerCase() == "config.sh";
    return QlListCard(
      title: bean.title ?? "",
      subtitle: isMainConfig
          ? "主配置文件 · 双击可编辑"
          : "${_fileKind(bean.title)} · 点击查看",
      leading: const QlListCardLeading(icon: CupertinoIcons.doc_text),
      onTap: () {
        Navigator.of(context)
            .pushNamed(Routes.routeConfigDetail, arguments: {"bean": bean});
      },
      onDoubleTap: onDoubleTap,
    );
  }
}
