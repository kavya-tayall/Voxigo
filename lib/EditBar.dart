import 'package:flutter/material.dart';
import 'Buttons.dart';
import 'homePage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'grid.dart';
import 'package:uuid/uuid.dart';

class EditBar extends StatelessWidget {
  final dynamic data;

  EditBar({required this.data});
  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            DataWidget(

            data: data,
            onDataChange: context.findAncestorStateOfType<HomePageState>()!.modifyData,
            child: AddButton(data: data)),
            MoveButton(),
            EditButton(),
            RemoveButton(),
          ],
      );
  }
}

class AddButton extends StatefulWidget {
  final Map<String, dynamic> data;

  AddButton({required this.data});

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {

  void addVisibleButtons(FirstButton button) {
    final dataWidget = DataWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        Map<String, dynamic> nestedData = dataWidget.data;

        // Ensure the 'buttons' key exists at the top level
        if (!nestedData.containsKey('buttons')) {
          nestedData['buttons'] = []; // Initialize if not present
        }

        // Generate a unique ID for the new button
        final buttonId = Uuid().v4(); // Generate a UUID
        final newButton = button.toJson()..['id'] = buttonId;

        // Add the button to the top-level buttons list
        nestedData['buttons'].add(newButton); // Add button to the list

        // Notify the widget that the data has changed
        dataWidget.onDataChange(dataWidget.data);

        // Save the updated data to file
        saveUpdatedData(dataWidget.data);

        // Update the UI
        updateGrid();
      });
    } else {
      print('DataWidget is null');
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



  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),
      ),
      onPressed: () async {
        String? enteredText = await _showTextInputDialog(context);
        if (enteredText != null) {
          dynamic buttonData = searchButtonData(widget.data, enteredText);
          if (buttonData != null) {
            FirstButton button = _createFirstButtonFromData(buttonData);
            addVisibleButtons(button);
          } else {
            // Handle case where no button is found
            print("Button not found");
          }
        }
      },
      child: Icon(Icons.add),
    );


  }
}

  dynamic searchButtonData(Map<String, dynamic> data, String label) {
    for (var key in data.keys) {
      if (data[key] is Map<String, dynamic>) {
        var result = searchButtonData(data[key], label);
        if (result != null) {
          return result;
        }
      } else if (data[key] is List) {
        for (var item in data[key]) {
          if (item["label"] == label) {
            return item;
          }
        }
      }
    }
    return null;
  }

  FirstButton _createFirstButtonFromData(Map<String, dynamic> data) {
    return FirstButton(
      id: data["id"],
      imagePath: data["image_url"],
      text: data["label"],
      size: 60.0, // Adjust the size as needed
      onPressed: () {
        // Implement what happens when the button is pressed
      },
    );
  }

  Future<String?> _showTextInputDialog(BuildContext context) async {
    TextEditingController _controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Button'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Type here"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop(_controller.text);
              },
            ),
          ],
        );
      },
    );
  }








class MoveButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        print("move");
      },
      child: Icon(Icons.open_with),
    );
  }
}

class EditButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        print("edit");
      },
      child: Icon(Icons.edit),
    );
  }
}

class RemoveButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        print("remove");
      },
      child: Icon(Icons.delete),
    );
  }
}

