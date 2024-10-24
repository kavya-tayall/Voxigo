import 'package:flutter/material.dart';
import 'package:test_app/widgets/feelings_buttons.dart';


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
              child: Text(
                'How do you feel?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 90,
                  color: Colors.blueAccent,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 4.0),
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ],
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
