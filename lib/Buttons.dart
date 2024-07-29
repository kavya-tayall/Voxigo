import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirstButton extends StatefulWidget {
  @override
  State<FirstButton> createState() => _FirstButtonState();
}

class _FirstButtonState extends State<FirstButton> {
  @override


Widget build(BuildContext context) {
    var text = 'Hi';

    Card(
      elevation: 5,
    );

    return ElevatedButton(
      onPressed: () {
        print(text);
      },
      child: Column(
        children: <Widget>[
          Expanded(
            child: Image.asset('smiling-african-american-girl-greeting-waving-hand-saying-hi-209227263.webp'),
          ),
          Text(text),
        ],
      ),
    );

  }

  }