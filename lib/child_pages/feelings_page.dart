import 'package:flutter/material.dart';
import 'package:test_app/widgets/feelings_buttons.dart';

import 'home_page.dart';

Map<String, Map<String, Widget>> suggestions = {
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: GradientText(
                'How do you feel?',
                gradient: LinearGradient(colors: [Color(0xFFAC70F8), Color(0xFF7000FF)]),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 90,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              FeelingsButton(
                feeling: "Happy",
                imagePath: "assets/imgs/happy.png",
                suggestions: [],
              ),
              FeelingsButton(
                feeling: "Sad",
                imagePath: "assets/imgs/sad.png",
                suggestions: [],
              ),
              FeelingsButton(
                feeling: "Angry",
                imagePath: "assets/imgs/angry.png",
                suggestions: [],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FeelingsButton(
                feeling: "Nervous",
                imagePath: "assets/imgs/nervous.png",
                suggestions: [],
              ),
              FeelingsButton(
                feeling: "Bored",
                imagePath: "assets/imgs/bored.png",
                suggestions: [],
              ),
              FeelingsButton(
                feeling: "Tired",
                imagePath: "assets/imgs/tired.png",
                suggestions: [],
              ),
            ],
          )
        ],
      ),
    );
  }
}
