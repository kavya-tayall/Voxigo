import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'EditBar.dart';
import 'main.dart';
import 'Buttons.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  FlutterTts flutterTts = FlutterTts();
  List<FirstButton> _selectedButtons = [];
  List<FirstButton> get selectedButtons => _selectedButtons;

  Map<String, dynamic> _data = {}; // Initialize _data as an empty map
  bool _isLoading = true; // A flag to check if data is still loading

  @override
  void initState() {
    super.initState();
    _loadJsonData();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadJsonData() async {
    final jsonString = await rootBundle.loadString("assets/board_info/board.json");
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _data = Map.from(jsonData);
      _isLoading = false; // Data loading complete
    });
  }


  void addButton(FirstButton button)  {
    setState(() {
      _selectedButtons.add(button); // Modify the private _selectedButtons list directly
    });

  }

  void clearSelectedButtons() {
    setState(() {
      _selectedButtons.clear();
    });
  }

  void backspaceSelectedButtons() {
    setState(() {
      _selectedButtons.removeLast();
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: <Widget>[
          Container(
            height: 130,
            color: Colors.blueAccent,
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
                      onPressed: () {},
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),Container(
                    width: 2,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: Icon(Icons.backspace),
                      onPressed: backspaceSelectedButtons,
                      label: const Text('Backspace'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero,
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
                          borderRadius: BorderRadius.zero,
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
                      onPressed: () async {
                        for (FirstButton button in _selectedButtons){
                          print (button.text);
                          await flutterTts.speak(button.text);}
                      },
                      label: const Text('Play'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero,
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
                          borderRadius: BorderRadius.zero,
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
          EditBar(
            onButtonAdded: (FirstButton button) {
              addButton(button); // Add the button to visible buttons
            },),
            SizedBox(height: 20),
          ],
        );
      }

  }
}