import 'package:material_ui/material_ui.dart';

class ButtonWidget extends StatefulWidget {
  final GestureTapCallback onTap;

  final String? title;

  const ButtonWidget({
    super.key,
    required this.onTap,
    this.title,
  });

  @override
  ButtonWidgetState createState() => ButtonWidgetState();
}

class ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff5DD16F),
                Color(0xff089556),
              ],
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Center(
            child: Text(
              widget.title ?? "提交",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
