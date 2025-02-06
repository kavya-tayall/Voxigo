import 'package:flutter/material.dart';
import 'package:test_app/widgets/feelings_buttons.dart';
import 'package:test_app/auth_logic.dart';
import 'package:test_app/user_session_management.dart';

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
    final theme = Theme.of(context); // Access the current theme
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    if (isSessionValid == false) {
      return SessionExpiredWidget(
        onLogout: () => logOutUser(context),
      );
    }

    return Scaffold(
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
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 24 : 36,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    color: theme.shadowColor.withOpacity(0.5),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isMobile ? 16 : 18,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
