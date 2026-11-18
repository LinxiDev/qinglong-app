import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

import '../../main.dart';

class ChangeAccountPage extends ConsumerStatefulWidget {
  const ChangeAccountPage({super.key});

  @override
  ChangeAccountPageState createState() => ChangeAccountPageState();
}

class ChangeAccountPageState extends ConsumerState<ChangeAccountPage> {
  @override
  void initState() {
    super.initState();

    FocusManager.instance.primaryFocus?.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (MultiAccountUserInfoViewModel.maxAccount == 1 &&
          SpUtil.getInt(spVIP, defValue: typeNormal) != typeNormal) {
        "请杀掉App重新进入,即可启用多账号切换功能".toast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int count = getIt<MultiAccountUserInfoViewModel>().tokenBeans.length + 1;
    if (count > MultiAccountUserInfoViewModel.maxAccount) {
      count = MultiAccountUserInfoViewModel.maxAccount;
    }
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: ref.watch(themeProvider).themeMode == modeDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: kToolbarHeight,
                      ),
                      child: Icon(CupertinoIcons.clear_thick, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "轻触账号以切换身份使用",
                  style: TextStyle(
                    color: ref.watch(themeProvider).themeColor.titleColor(),
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 30),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index >=
                              getIt<MultiAccountUserInfoViewModel>()
                                  .tokenBeans
                                  .length ||
                          (getIt<MultiAccountUserInfoViewModel>()
                                      .tokenBeans
                                      .length <
                                  count &&
                              index == count - 1)) {
                        return addAccount(context, index);
                      }

                      var userInfo = getIt<UserInfoViewModel>(
                        instanceName: index.toString(),
                      );
                      final int currentIndex =
                          SingleAccountPageState.of(context)?.index ?? 0;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          context
                              .findAncestorStateOfType<MultiAccountPageState>()
                              ?.updateIndex(index);
                          Navigator.of(context).pop();
                        },
                        child: buildCell(userInfo, index, currentIndex),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox.shrink(),
                    itemCount: count,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCell(UserInfoViewModel model, int index, int currentIndex) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color primary = ref.watch(themeProvider).primaryColor;
    final bool isCurrent = index == currentIndex;
    final bool logged = model.token != null && model.token!.isNotEmpty;

    final String alias = (model.alias ?? "").trim().isNotEmpty
        ? model.alias!.trim()
        : "未命名面板";
    final String host = model.host ?? "";

    // 卡片内容（装饰由外层动态容器负责：滑动时方形、静止时圆角）
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // 头像：取别名的第一个字符
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: dark ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Text(
              alias.characters.first.toUpperCase(),
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 别名在上、域名在下
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        alias,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: themeColor.titleColor(),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "当前",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: themeColor.descColor(), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 登录状态徽标
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: logged
                  ? primary.withValues(alpha: dark ? 0.22 : 0.10)
                  : (dark ? const Color(0xFF3A2222) : const Color(0xFFFDEEEE)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              logged ? "已登录" : "未登录",
              style: TextStyle(
                color: logged ? primary : const Color(0xFFEA4D3E),
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
    if (model.host == null || model.host!.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: themeColor.settingBgColor(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? primary
                : (dark ? const Color(0xFF2E2E31) : const Color(0xFFE6E8EC)),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Slidable(
        key: ValueKey(model.host),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              backgroundColor: const Color(0xffEA4D3E),
              onPressed: (_) {
                if (model.token != null && model.token!.isNotEmpty) {
                  "请先退出登录，再删除".toast();
                  return;
                }

                showCupertinoDialog(
                  context: context,
                  useRootNavigator: false,
                  builder: (childContext) => CupertinoAlertDialog(
                    title: const Text("温馨提示"),
                    content: const Text("确定删除吗?"),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text(
                          "取消",
                          style: TextStyle(color: Color(0xff999999)),
                        ),
                        onPressed: () {
                          Navigator.of(childContext).pop();
                        },
                      ),
                      CupertinoDialogAction(
                        child: Text(
                          "确定",
                          style: TextStyle(
                            color: ref.watch(themeProvider).primaryColor,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(childContext).pop();
                          getIt<MultiAccountUserInfoViewModel>()
                              .removeHistoryAccount(model.host);
                          getIt<UserInfoViewModel>(
                            instanceName: index.toString(),
                          ).clearCurrentInfo(index);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
              foregroundColor: Colors.white,
              icon: CupertinoIcons.delete,
            ),
          ],
        ),
        child: Builder(
          builder: (BuildContext itemContext) {
            return ValueListenableBuilder<ActionPaneType>(
              valueListenable: Slidable.of(itemContext)!.actionPaneType,
              builder: (context, paneType, cardChild) {
                final bool sliding = paneType != ActionPaneType.none;
                return Container(
                  decoration: BoxDecoration(
                    color: themeColor.settingBgColor(),
                    borderRadius: BorderRadius.circular(sliding ? 0 : 14),
                    border: sliding
                        ? null
                        : Border.all(
                            color: isCurrent
                                ? primary
                                : (dark
                                      ? const Color(0xFF2E2E31)
                                      : const Color(0xFFE6E8EC)),
                            width: isCurrent ? 1.5 : 1,
                          ),
                  ),
                  child: cardChild,
                );
              },
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget addAccount(BuildContext context, int index) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.findAncestorStateOfType<MultiAccountPageState>()?.updateIndex(
          index,
        );
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: themeColor.settingBgColor(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? const Color(0xFF2E2E31) : const Color(0xFFE6E8EC),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ref
                    .watch(themeProvider)
                    .primaryColor
                    .withValues(alpha: dark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(
                CupertinoIcons.add,
                size: 20,
                color: ref.watch(themeProvider).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "添加账号",
              style: TextStyle(
                color: themeColor.titleColor(),
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
