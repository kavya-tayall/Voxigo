
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class FirstButton extends StatefulWidget {
  final String imagePath;
  final String text;
  final double size;

  const FirstButton({Key? key, required this.imagePath, required this.text, required this.size}) : super(key: key);

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
          double currentWidth = (context.read<MyAppState>().getSelectedButtons().length+1) * 120;

          if (currentWidth <= width) {
            context.read<MyAppState>().addSelectedButton(widget);
          }
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

class FolderButton extends StatefulWidget {
  final String imagePath;
  final String text;
  final int ind;
  final List<Map> btns;
  final double size;

  FolderButton({Key? key, required this.imagePath, required this.text, required this.ind, required this.btns, required this.size}) : super(key: key);

  @override
  State<FolderButton> createState() => _FolderButtonState();
}

class _FolderButtonState extends State<FolderButton> {
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ElevatedButton(
        onPressed: () {
          context.read<MyAppState>().updateGridPath(widget.ind.toString());
          context.read<MyAppState>().updateGridPath("buttons");
          context.read<MyAppState>().updateGrid(widget.btns[widget.ind]["buttons"]);
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
