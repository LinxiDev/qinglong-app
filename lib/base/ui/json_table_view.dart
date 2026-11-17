import 'package:material_ui/material_ui.dart';

/// 轻量 JSON 表格视图（替代已停止维护的 json_table 组件）。
///
/// 支持根节点为 `List<Map>` 或单个 `Map` 的 JSON 数据，
/// 自动合并所有键作为表头，可横向/纵向滚动。
class JsonTableView extends StatelessWidget {
  final dynamic json;

  const JsonTableView(
    this.json, {
    super.key,
    this.maxColumnWidth = 200,
    this.rowHeight = 50,
  });

  final double maxColumnWidth;
  final double rowHeight;

  static const double minColumnWidth = 90;

  List<Map<String, dynamic>> get _rows {
    if (json is List) {
      return json.whereType<Object?>().map<Map<String, dynamic>>((e) {
        if (e is Map) return e.map((k, v) => MapEntry(k.toString(), v));
        return {"value": e};
      }).toList();
    }
    if (json is Map) {
      return [json.map((k, v) => MapEntry(k.toString(), v))];
    }
    return [];
  }

  List<String> get _headers {
    final List<String> headers = [];
    for (final row in _rows) {
      for (final key in row.keys) {
        if (!headers.contains(key)) headers.add(key);
      }
    }
    return headers;
  }

  String _cellText(dynamic value) {
    if (value == null) return "";
    if (value is Map || value is List) return value.toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> headers = _headers;
    final List<Map<String, dynamic>> rows = _rows;

    if (headers.isEmpty) {
      return const Center(child: Text("暂无数据"));
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width:
              headers.length *
              (maxColumnWidth < minColumnWidth
                  ? minColumnWidth
                  : maxColumnWidth),
          child: ListView.builder(
            itemCount: rows.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildRow(headers, header: true, context: context);
              }
              final row = rows[index - 1];
              return _buildRow(
                headers.map((h) => _cellText(row[h])).toList(),
                header: false,
                context: context,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    List<String> values, {
    required bool header,
    required BuildContext context,
  }) {
    final Color borderColor = Theme.of(context).dividerColor
        .withValues(alpha: 0.4);

    return Row(
      children: values.map((value) {
        return Container(
          width: maxColumnWidth < minColumnWidth
              ? minColumnWidth
              : maxColumnWidth,
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(width: 0.5, color: borderColor),
            color: header
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Text(
            value,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: header ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}
