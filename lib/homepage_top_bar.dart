import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'Buttons.dart';


class HomeTopBar extends StatelessWidget {
  final List<FirstButton> clickedButtons;

  HomeTopBar({required this.clickedButtons});


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Row(children: clickedButtons.map((button) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                width: 50, // Adjust size as needed
                height: 50,
                child: button,
              );
            }).toList(),)),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            children:[
              Padding(padding: EdgeInsets.all(16), child: ElevatedButton.icon(icon: Icon(Icons.clear), onPressed: () => {}, label: const Text('Clear'),)),
              Padding(padding: EdgeInsets.all(16), child: ElevatedButton.icon(icon: Icon(Icons.play_arrow), onPressed: () => {}, label: const Text('Play'),)),
              Padding(padding: EdgeInsets.all(16), child: ElevatedButton.icon(icon: Icon(Icons.auto_mode), onPressed: () => {}, label: const Text('Helper'),))
            ]
          ),
        )
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




