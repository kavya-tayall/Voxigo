import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'Buttons.dart';

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({super.key});

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Row(children: [
          ClickedBox(),
          ClickedBox(),
          ClickedBox(),
          ClickedBox(),
          ClickedBox(),
          ClickedBox(),
          ClickedBox(),
        ])),
        Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.clear),
              onPressed: () => {},
              label: const Text('Clear'),
            )),

        Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              onPressed: () => {},
              label: const Text('Play'),
            )),

        Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.auto_mode),
              onPressed: () => {},
              label: const Text('Helper'),
            ))
      ],
    );
  }
}

class ClickedBox extends StatefulWidget {
  const ClickedBox({super.key});

  @override
  State<ClickedBox> createState() => _ClickedBoxState();
}

class _ClickedBoxState extends State<ClickedBox> {
  Widget inside = SizedBox(
    width: 150,
    height: 100,
    child: Icon(Icons.add_outlined),
  );

  void changeBox() {
    setState(() {
      this.inside = FirstButton();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: this.inside);
  }
}
