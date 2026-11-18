import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qinglong_app/module/task/task_viewmodel.dart';

/// 回归：生命周期回调在 GetIt 未注册时不得崩溃。
///
/// GitHub Actions integration-test.yml 曾因此失败：
/// `Bad state: GetIt: Object/factory with name 0 and type SystemBean
/// is not registered` —— 测试 teardown 后迟到的 App 生命周期事件
/// 触发 TaskPageState.didChangeAppLifecycleState → loadData。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> buildContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('loadData 在 SystemBean 未注册时安全返回', (tester) async {
    final BuildContext context = await buildContext(tester);
    final vm = TaskViewModel();

    // 不注册 SystemBean，直接复现 CI 崩溃路径
    await vm.loadData(context);

    expect(vm.list, isEmpty, reason: '守卫应提前返回，不发起任何加载');
  });

  testWidgets('runAllTasks 在 SystemBean 未注册时安全返回', (tester) async {
    final BuildContext context = await buildContext(tester);
    final vm = TaskViewModel();

    vm.runAllTasks(context);

    expect(vm.runAllTasked, isFalse, reason: '守卫应提前返回，不触发批量运行');
  });
}
