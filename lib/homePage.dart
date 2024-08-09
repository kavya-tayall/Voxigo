import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'EditBar.dart';
import 'main.dart';
import 'Buttons.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  List<FirstButton> _selectedButtons = [];
  List<FirstButton> get selectedButtons => _selectedButtons;

  Map<String, dynamic> _data = {}; // Initialize _data as an empty map
  bool _isLoading = true; // A flag to check if data is still loading

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    final jsonString = await rootBundle.loadString("assets/board_info/board.json");
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _data = Map.from(jsonData);
      _isLoading = false; // Data loading complete
    });
  }

  void addButton(FirstButton button) {
    setState(() {
      selectedButtons.add(button);
    });
  }

  void clearSelectedButtons() {
    setState(() {
      selectedButtons.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
      if (_isLoading){
        return Center(child: CircularProgressIndicator());
      } else{
        return Column(
          children: <Widget>[
            Container(
              height: 130,
              color: Colors.blueAccent,
              padding: EdgeInsets.all(8),
              child: HomeTopBar(clickedButtons: selectedButtons),

            ),
            Container(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Visibility(
                      visible: true,
                      child: TextButton.icon(
                        icon: Icon(Icons.arrow_back_rounded),
                        onPressed: () {
                        },
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.zero, // Make the corners sharp
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      color: Colors.grey,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Icons.clear),
                        onPressed: clearSelectedButtons,
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.zero, // Make the corners sharp
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      color: Colors.grey,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () {
                          // Implement play logic
                        },
                        label: const Text('Play'),
                        style: TextButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.zero, // Make the corners sharp
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      color: Colors.grey,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Icons.auto_mode),
                        onPressed: () {
                          // Implement helper logic
                        },
                        label: const Text('Helper'),
                        style: TextButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.zero, // Make the corners sharp
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: Grid(
                    data: _data,

                    onButtonPressed: addButton,
                  ),
                ),
              ),
            ),
            EditBar(),
            SizedBox(height: 20),
          ],
        );
      }

  }
}
