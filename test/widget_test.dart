import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/ui/json_table_view.dart';

void main() {
  testWidgets('JsonTableView 渲染表头与单元格', (WidgetTester tester) async {
    final dynamic json = [
      {"name": "任务A", "status": 1},
      {"name": "任务B", "status": 0},
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: JsonTableView(json),
          ),
        ),
      ),
    );

    expect(find.text("name"), findsOneWidget);
    expect(find.text("status"), findsOneWidget);
    expect(find.text("任务A"), findsOneWidget);
    expect(find.text("任务B"), findsOneWidget);
  });

  testWidgets('JsonTableView 处理空数据', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JsonTableView(null),
        ),
      ),
    );

    expect(find.text("暂无数据"), findsOneWidget);
  });
}
