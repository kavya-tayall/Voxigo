import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';


class FirstButton extends StatefulWidget {
  final String imagePath;
  final String text;

  const FirstButton({Key? key, required this.imagePath, required this.text}) : super(key: key);

  @override
  State<FirstButton> createState() => _FirstButtonState();
}

class _FirstButtonState extends State<FirstButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,  // Set the width of the button
      height: 100, // Set the height of the button
      child: ElevatedButton(
        onPressed: () {
          double width = MediaQuery.sizeOf(context).width;
          double currentWidth = (context.read<MyAppState>().getSelectedButtons().length+1) * 120;

          if (currentWidth <= width) {
            context.read<MyAppState>().addSelectedButton(widget);
          }
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Ensure no rounding to keep it square
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch content horizontally
          children: <Widget>[
            Expanded(
              child: Image.asset(
                widget.imagePath, // Use the passed image path
                width: 50.0,
                height: 20.0,
                fit: BoxFit.cover, // Ensure the image covers the button
              ),
            ),
            Text(
              widget.text, // Use the passed text
              textAlign: TextAlign.center, // Center text horizontally
            ),
          ],
        ),
      ),
    );
  }
}



class FolderButton extends StatefulWidget {
  String imagePath;
  String text;
  int ind;
  List<Map> btns;
  FolderButton({Key? key, required this.imagePath, required this.text, required this.ind, required this.btns}) : super(key: key);

  @override
  State<FolderButton> createState() => _FolderButton();
}

class _FolderButton extends State<FolderButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,  // Set the width of the button
      height: 100, // Set the height of the button
      child: ElevatedButton(
        onPressed: () {
          context.read<MyAppState>().updateGridPath(widget.ind.toString());
          context.read<MyAppState>().updateGridPath("buttons");
          context.read<MyAppState>().updateGrid(widget.btns[widget.ind]["buttons"]);
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Ensure no rounding to keep it square
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch content horizontally
          children: <Widget>[
            Expanded(
              child: Image.asset(
                widget.imagePath, // Use the passed image path
                width: 50.0,
                height: 20.0,
                fit: BoxFit.cover, // Ensure the image covers the button
              ),
            ),
            Text(
              widget.text, // Use the passed text
              textAlign: TextAlign.center, // Center text horizontally
            ),
          ],
        ),
      ),
    );
  }
}


