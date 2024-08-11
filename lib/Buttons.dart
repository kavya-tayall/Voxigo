
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'homePage.dart';


class FirstButton extends StatefulWidget {
  final String id;
  final String imagePath;
  final String text;
  final double size;
  final VoidCallback onPressed;

  const FirstButton({Key? key, required this.id, required this.imagePath, required this.text, required this.size, required this.onPressed}) : super(key: key);

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "image_url": imagePath,
      "label": text,
      "folder": false
    };
  }

  @override
  State<FirstButton> createState() => _FirstButtonState();
}

class _FirstButtonState extends State<FirstButton> {



@override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ElevatedButton(
        onPressed: () {
          double width = MediaQuery.sizeOf(context).width;
          double currentWidth = widget.size * (context.findAncestorStateOfType<HomePageState>()?.selectedButtons.length ?? 0 + 1);
          print(width);
          print(currentWidth);

          if (currentWidth <= width) {
            widget.onPressed();
          }
          else print("oops overflowed");
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              widget.text,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FolderButton extends StatelessWidget {
  final String imagePath;
  final String text;
  final int ind;
  final double size;

  final VoidCallback onPressed;

  FolderButton({required this.imagePath, required this.text, required this.ind, required this.size, required this.onPressed});

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              text,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
