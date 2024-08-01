import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'Buttons.dart';


class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Row(children: [
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
          ClickedBox(inside: SizedBox(width: 150, height: 100, child: Icon(Icons.add_outlined))),
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


class ClickedBox extends StatelessWidget {
  Widget inside = Placeholder();

  ClickedBox({required this.inside});

  @override
  Widget build(BuildContext context) {
    return Container(child: this.inside);
  }
}




