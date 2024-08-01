import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'Buttons.dart';
import 'package:provider/provider.dart';
import 'main.dart';



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
              return Padding(
                padding: EdgeInsets.all(10),
                child: button,
              );
            }).toList(),)),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            children:[
              Padding(padding: EdgeInsets.all(16), child: ElevatedButton.icon(icon: Icon(Icons.clear), onPressed: () {
    context.read<MyAppState>().clearSelectedButtons();


    }, label: const Text('Clear'),)),
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




