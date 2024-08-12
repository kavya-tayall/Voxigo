import 'package:flutter/material.dart';
import 'Buttons.dart';
import 'homePage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'grid.dart';
import 'package:uuid/uuid.dart';

import 'main.dart';

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
            onDataChange: context.findAncestorStateOfType<BasePageState>()!.modifyData,
            child: AddButton(data: data)),
            RemoveButton(),
          ],
      );
  }
}

class AddButton extends StatefulWidget {
  final Map<String, dynamic> data;

  AddButton({required this.data});

  @override
  State<AddButton> createState() => AddButtonState();
}

class AddButtonState extends State<AddButton> {

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
        final newButton = button.toJson()
          ..['id'] = buttonId;

        // Add the button to the top-level buttons list
        nestedData['buttons'].add(newButton); // Add button to the list

        // Notify the widget that the data has changed
        dataWidget.onDataChange(dataWidget.data);

        // Save the updated data to file
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

        // Update the UI
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }


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
      size: 60.0,
      // Adjust the size as needed
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
}






class RemoveButton extends StatefulWidget{
  @override
  State<RemoveButton> createState() => RemoveButtonState();
}

class RemoveButtonState extends State<RemoveButton> {
  bool isRemovalMode = false;


  void removeVisibleButton(FirstButton button) {
    final dataWidget = DataWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        Map<String, dynamic> nestedData = dataWidget.data;

        // Check if the 'buttons' key exists at the top level
        if (nestedData.containsKey('buttons')) {
          List<dynamic> buttonList = nestedData['buttons'] as List<dynamic>;

          // Find and remove the button with the specified ID
          buttonList.removeWhere((b) => b['id'] == button.id);

          // Notify the widget that the data has changed
          dataWidget.onDataChange(dataWidget.data);

          // Save the updated data to file
          context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

          // Update the UI
          context.findAncestorStateOfType<HomePageState>()?.updateGrid();

        } else {
          print('No buttons found at the top level');
        }
      });
    } else {
      print('DataWidget is null');
    }

    print("Button with ID ${button.id} is removed");
  }

  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        context.findAncestorStateOfType<HomePageState>()?.changeRemovalState();
        isRemovalMode = !isRemovalMode;


      },
      child: Icon(isRemovalMode ? Icons.check : Icons.delete),
    );
  }
}

