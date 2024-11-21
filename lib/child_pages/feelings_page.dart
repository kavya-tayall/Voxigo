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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feelings'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.05,
          horizontal: screenWidth * 0.05,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Text
            Text(
              'How do you feel?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 24 : 36,
                color: Colors.blueAccent,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Center-Aligned Feelings Buttons
            Wrap(
              alignment: WrapAlignment.center, // Center-aligned buttons
              spacing: isMobile ? 20 : screenWidth * 0.05,
              runSpacing: isMobile ? 20 : screenHeight * 0.03,
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
            ),
            SizedBox(height: screenHeight * 0.05),

            // Footer Text
            Text(
              "Tap on a feeling to explore suggestions!",
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}