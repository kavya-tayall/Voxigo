import 'package:flutter/material.dart';

import 'buttons_screen.dart';

class ButtonsTable extends StatelessWidget {
  final String searchText;
  final List<dynamic> selectedButtons;
  final bool isLoading;

  ButtonsTable({
    required this.searchText,
    required this.selectedButtons,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (selectedButtons.isEmpty) {
      return Center(child: Text('No buttons selected yet'));
    }

    Map<String, int> buttonCounts = {};
    for (var button in selectedButtons) {
      String text = button['text'];
      if (buttonCounts.containsKey(text)) {
        buttonCounts[text] = buttonCounts[text]! + 1;
      } else {
        buttonCounts[text] = 1;
      }
    }

    List<MapEntry<String, int>> sortedButtons = buttonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    sortedButtons = sortedButtons
        .where((entry) =>
        entry.key.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: sortedButtons.length,
      itemBuilder: (context, index) {
        String text = sortedButtons[index].key;
        int quantity = sortedButtons[index].value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color(0xffdde8ff), // New color for the tile
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              height: 80, // Reduced height of the tile
              child: Stack(
                children: [
                  // "See More" button aligned to the far left
                  Positioned(
                    bottom: 8,
                    left: 0, // Moved to the left
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ButtonDetailsScreen(
                              buttonText: text,
                              buttonInstances: selectedButtons
                                  .where((button) => button['text'] == text)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      child: Text('See More'),
                    ),
                  ),

                  // Button text
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Quantity indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          '$quantity',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
