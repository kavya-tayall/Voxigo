import 'package:flutter/material.dart';
import 'grid.dart';
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
  List<dynamic> _pathOfBoard = ["buttons"];
  Map<String, List> _data = {};

  List<FirstButton> _selectedButtons = [];
  List<FirstButton> get selectedButtons => _selectedButtons;

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

  // Update the path of the board
  void _updatePathOfBoard(List<dynamic> newPath) {
    setState(() {
      _pathOfBoard = List.from(newPath);
    });
  }

  // Modify the data (you can customize this based on your app's logic)
  void _modifyData(Map<String, List> newData) {
    setState(() {
      _data = Map.from(newData);
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
                  child: PathWidget(
                    onPathChange: _updatePathOfBoard,
                    pathOfBoard: _pathOfBoard,
                    child: DataWidget(
                      onDataChange: _modifyData,
                      data: _data,
                      child: Grid(onButtonPressed: addButton),
                    ),
                  ),
                ),
              ),
            ),
            EditBar(
              data: _data,
              onButtonAdded: (FirstButton button) {
              addButton(button); // Add the button to visible buttons
            },),
            SizedBox(height: 20),
          ],
        );
      }

  }
}

class PathWidget extends InheritedWidget {
  const PathWidget({
    required super.child,
    required this.pathOfBoard,
    required this.onPathChange,
  });

  final List pathOfBoard;
  final void Function(List<dynamic> newPath) onPathChange;

  static PathWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PathWidget>();
  }

  @override
  bool updateShouldNotify(PathWidget oldWidget) {
    return oldWidget.pathOfBoard != pathOfBoard;
  }
}


class DataWidget extends InheritedWidget {
  const DataWidget({
    required super.child,
    required this.data,
    required this.onDataChange,
  });

  final Map <String, List> data;
  final void Function(Map<String, List> newData) onDataChange;

  static DataWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DataWidget>();
  }

  @override
  bool updateShouldNotify(DataWidget oldWidget) {
    return oldWidget.data != data;
  }
}
