import 'package:flutter/material.dart';

class FiveThingsToSeePage extends StatefulWidget {
  @override
  _FiveThingsToSeePageState createState() => _FiveThingsToSeePageState();
}

class _FiveThingsToSeePageState extends State<FiveThingsToSeePage> {
  final List<String> _itemsToSpot = [
    "A red apple",
    "A blue ball",
    "A green tree",
    "A yellow sun",
    "A white cloud"
  ];

  final Set<String> _spottedItems = {};

  void _toggleItem(String item) {
    setState(() {
      if (_spottedItems.contains(item)) {
        _spottedItems.remove(item);
      } else {
        _spottedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Spot the Wonders",
          textAlign: TextAlign.center,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Look around and tap on the items you see!",
              style: TextStyle(
                fontSize: isMobile ? 18 : 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _itemsToSpot.length,
                itemBuilder: (context, index) {
                  final item = _itemsToSpot[index];
                  final isSpotted = _spottedItems.contains(item);

                  return GestureDetector(
                    onTap: () => _toggleItem(item),
                    child: Card(
                      color: isSpotted ? Colors.greenAccent : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              isSpotted
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSpotted ? Colors.green : Colors.grey,
                              size: isMobile ? 24 : 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _spottedItems.length == _itemsToSpot.length
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Great job! You spotted all items! 🎉"),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueAccent,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                "I'm Done!",
                style: TextStyle(
                  fontSize: isMobile ? 18 : 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
