import 'package:flutter/material.dart';
import '../widgets/grid.dart';
import '../widgets/homepage_top_bar.dart';
import '../widgets/edit_bar.dart';
import '../main.dart';
import '../widgets/buttons.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataWidget extends InheritedWidget {
  const DataWidget({
    required super.child,
    required this.data,
    required this.onDataChange,
  });

  final Map<String, List> data;
  final void Function(Map<String, List> newData) onDataChange;

  static DataWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DataWidget>();
  }

  @override
  bool updateShouldNotify(DataWidget oldWidget) {
    return oldWidget.data != data;
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

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  FlutterTts flutterTts = FlutterTts();

  List<FirstButton> _selectedButtons = [];

  List<FirstButton> get selectedButtons => _selectedButtons;

  bool inRemovalState = false;

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  void changeRemovalState() {
    setState(() {
      inRemovalState = !inRemovalState;
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

  void backspaceSelectedButtons() {
    setState(() {
      _selectedButtons.removeLast();
    });
  }

  void removeVisibleButton(FirstButton button) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);


    setState(() {
      dynamic nestedData = dataWidget?.data;
      for (var folder in pathWidget!.pathOfBoard) {
        nestedData = nestedData[folder];
      }


      nestedData.removeWhere((b) => b['id'] == button.id);
      dataWidget?.onDataChange(dataWidget.data);

      saveUpdatedData(dataWidget!.data);

      updateGrid();
    });

    print("Button with ID ${button.id} is removed");
  }

  Future<void> removeFolder(int folderIndex) async {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    dynamic nestedData = dataWidget?.data;
    for (var folder in pathWidget!.pathOfBoard) {
      nestedData = nestedData[folder];
    }

    // Show confirmation dialog before deleting the folder
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Folder"),
          content: Text("Are you sure you want to delete this folder and all its contents?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    // If confirmed, remove the folder
    if (confirmed == true) {
      setState(() {
        nestedData.removeAt(folderIndex); // Remove the folder from the list

        // Notify that the data has changed
        dataWidget?.onDataChange(dataWidget.data);

        // Save the updated data to file
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget!.data);

        // Update the UI
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });

      print("Folder at index $folderIndex removed");
    }
  }

  Future<void> updateGrid() async {
    final gridState = context.findAncestorStateOfType<GridState>();
    gridState?.updateVisibleButtons();
  }

  Future<void> saveUpdatedData(Map<String, dynamic> updatedData) async {
    String jsonString = jsonEncode(updatedData);
    await writeJsonToFile(jsonString);
    print('Data saved to board.json in documents directory');
  }

  Future<void> writeJsonToFile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/board.json');
    await file.writeAsString(jsonString);
  }

  Function(FirstButton button) selectOnPressedfunction() {
    if (!inRemovalState) {
      return addButton;
    } else {
      return removeVisibleButton;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorStateOfType<BasePageState>()!.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
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
                  PathWidget(
                    onPathChange: context.findAncestorStateOfType<BasePageState>()!.updatePathOfBoard,
                    pathOfBoard: context.findAncestorStateOfType<BasePageState>()!.pathOfBoard,
                    child: Visibility(
                      visible: true,
                      child: TextButton.icon(
                        icon: Icon(Icons.arrow_back_rounded),
                        onPressed: () => context
                            .findAncestorStateOfType<BasePageState>()
                            ?.goBack(),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius:
                                BorderRadius.zero, // Make the corners sharp
                          ),
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
                      icon: Icon(Icons.backspace),
                      onPressed: backspaceSelectedButtons,
                      label: const Text('Backspace'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius:
                              BorderRadius.zero, // Make the corners sharp
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
                          borderRadius:
                              BorderRadius.zero, // Make the corners sharp
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
                        for (FirstButton button in _selectedButtons) {
                          print(button.text);
                          await flutterTts.speak(button.text);
                        }
                        // Implement play logic
                      },
                      label: const Text('Play'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius:
                              BorderRadius.zero, // Make the corners sharp
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
                      icon: Icon(Icons.stop),
                      onPressed: () {
                        flutterTts.stop();
                      },
                      label: const Text('Stop'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius:
                              BorderRadius.zero, // Make the corners sharp
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
                  onPathChange: context.findAncestorStateOfType<BasePageState>()!.updatePathOfBoard,
                  pathOfBoard: context.findAncestorStateOfType<BasePageState>()!.pathOfBoard,
                  child: DataWidget(
                    onDataChange: context.findAncestorStateOfType<BasePageState>()!.modifyData,
                    data:
                        context.findAncestorStateOfType<BasePageState>()!.data,
                    child: Grid(onButtonPressed: selectOnPressedfunction()),
                  ),
                ),
              ),
            ),
          ),
          PathWidget(
            onPathChange: context
                .findAncestorStateOfType<BasePageState>()!
                .updatePathOfBoard,
            pathOfBoard:
                context.findAncestorStateOfType<BasePageState>()!.pathOfBoard,
            child: DataWidget(
              data: context.findAncestorStateOfType<BasePageState>()!.data,
              onDataChange:
                  context.findAncestorStateOfType<BasePageState>()!.modifyData,
              child: EditBar(
                data: context.findAncestorStateOfType<BasePageState>()?.data,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      );
    }
  }
}
