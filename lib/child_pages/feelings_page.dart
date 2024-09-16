import 'package:flutter/material.dart';
import 'package:test_app/widgets/feelings_buttons.dart';



Map<String, Map<String, Widget>> suggestions =
{
  "Angry": {},
  "Happy": {},
  "Sad": {},
  "Tired": {},
  "Bored": {},
  "Nervous": {},
};

class FeelingsPage extends StatelessWidget {
  const FeelingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Center(
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 5, style: BorderStyle.solid))),
                child: Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 10), child: Text("How do you feel?", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
              ),
            )),
        body:
        Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            FeelingsButton(
              feeling: "Happy",
              imagePath: "assets/imgs/happy.png",
              suggestions: [],
            ), FeelingsButton(
              feeling: "Sad",
              imagePath: "assets/imgs/sad.png",
              suggestions: [],
            ),FeelingsButton(
              feeling: "Angry",
              imagePath: "assets/imgs/angry.png",
              suggestions: [],
            ),
          ]),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            FeelingsButton(
              feeling: "Nervous",
              imagePath: "assets/imgs/nervous.png",
              suggestions: [],
            ), FeelingsButton(
            feeling: "Bored",
            imagePath: "assets/imgs/bored.png",
            suggestions: [],
          ),FeelingsButton(
            feeling: "Tired",
            imagePath: "assets/imgs/tired.png",
            suggestions: [],
          ),
          ])
        ]));
  }
}


