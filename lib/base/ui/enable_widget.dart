import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class StatusWidget extends ConsumerWidget {
  final String title;
  final Color color;

  const StatusWidget({
    Key? key,
    required this.title,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }
}
