import 'package:flutter/material.dart';





class HomepageTopBar extends StatelessWidget {
  const HomepageTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        ClickedBox(),
        ClickedBox(),
        ClickedBox(),
        ClickedBox(),
        ClickedBox(),
        ClickedBox(),
        ClickedBox(),
        ClickedBox(),
        ElevatedButton.icon(
          icon: Icon(Icons.play_arrow),
          onPressed: () => {},
          label: const Text('Play'),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.computer),
          onPressed: () => {},
          label: const Text('Play'),
        )
      ]
    );
  }
}

class ClickedBox extends StatefulWidget {
  const ClickedBox({super.key});

  @override
  State<ClickedBox> createState() => _ClickedBoxState();
}

class _ClickedBoxState extends State<ClickedBox> {
  @override
  Widget build(BuildContext context) {
    return Placeholder(

    );
  }
}


