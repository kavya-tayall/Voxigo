import 'package:flutter/material.dart';
import 'Buttons.dart';


class EditBar extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(FirstButton) onButtonAdded;

  EditBar({required this.data, required this.onButtonAdded});
  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AddButton(data: data, onButtonAdded: onButtonAdded),
            MoveButton(),
            EditButton(),
            RemoveButton(),
          ],
      );
  }
}

class AddButton extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(FirstButton) onButtonAdded;

  AddButton({required this.data, required this.onButtonAdded});

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
          dynamic buttonData = searchButtonData(data, enteredText);
          if (buttonData != null) {
            FirstButton button = _createFirstButtonFromData(buttonData);
            onButtonAdded(button);
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

