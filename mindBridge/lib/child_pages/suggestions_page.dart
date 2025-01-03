import 'package:flutter/material.dart';

Map<String, String> temp = {
  "Fidget Spinner": "/fidget",
  "Deep Breathing": "/breathing",
  "Coloring": "/coloring",
  "Music": "/music",
  "Calm Down with 54321": "/54321"
};

class SuggestionsPage extends StatelessWidget {
  const SuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Suggestions",
          textAlign: TextAlign.center,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: temp.length,
        itemBuilder: (BuildContext context, int index) {
          final suggestion = temp.keys.toList()[index];
          print('suggestion $suggestion');
          String imagePath = "";
          if (suggestion == "Fidget Spinner") {
            imagePath = "assets/imgs/fidgetspinner.png"; // Placeholder path
          } else if (suggestion == "Deep Breathing") {
            imagePath = "assets/imgs/deepbreathing.png"; // Placeholder path
          } else if (suggestion == "Coloring") {
            imagePath = "assets/imgs/coloring.png"; // Placeholder path
          } else if (suggestion == "Music") {
            imagePath = "assets/imgs/music.png"; // Placeholder path
          } else if (suggestion == "Calm Down with 54321") {
            imagePath = "assets/imgs/calmdown.png"; // Placeholder path
          }
          final route = temp.values.toList()[index];

          return SuggestionTile(
            suggestion: suggestion,
            imagePath: imagePath,
            route: route,
            screenWidth: screenWidth,
          );
        },
      ),
    );
  }
}

class SuggestionTile extends StatelessWidget {
  final String suggestion;
  final String imagePath;
  final String route;
  final double screenWidth;

  const SuggestionTile({
    Key? key,
    required this.suggestion,
    required this.imagePath,
    required this.route,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: isMobile ? 100 : 150,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColorLight,
            elevation: 3.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: isMobile ? 60 : 80,
                height: isMobile ? 60 : 80,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  suggestion,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 36,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
