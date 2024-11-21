import 'package:flutter/material.dart';
import 'buttons.dart';

class HomeTopBar extends StatelessWidget {
  final List<FirstButton> clickedButtons;

  HomeTopBar({required this.clickedButtons});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate button size based on screen width
    int maxButtons = 8; // Maximum buttons visible in the top bar
    double buttonSize = (screenWidth / maxButtons) - 15; // Adjust for padding

    return SizedBox(
      height: buttonSize + 10, // Adjust height to fit buttons with padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: clickedButtons.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(5), // Space between buttons
            child: FirstButton(
              id: clickedButtons[index].id,
              imagePath: clickedButtons[index].imagePath,
              text: clickedButtons[index].text,
              size: buttonSize, // Dynamically set button size
              onPressed: clickedButtons[index].onPressed,
            ),
          );
        },
      ),
    );
  }
}