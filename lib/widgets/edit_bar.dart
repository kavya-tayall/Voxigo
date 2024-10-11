import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'child_provider.dart';

import '../child_pages/home_page.dart';
import 'buttons.dart';



// need to finish add button functionality


class EditBar extends StatelessWidget {
  final dynamic data;

  EditBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        AddButton(data: data),
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
  final Color buttonColor = Colors.lightBlue;
  final Color iconColor = Colors.white;
  final double buttonSize = 60.0;

  List<dynamic> pictogramsData = [];
  final ImagePicker _picker = ImagePicker();
  var _isUploading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    String jsonString = await rootBundle.loadString('assets/board_info/pictograms.json');
    List<dynamic> data = jsonDecode(jsonString);
    setState(() {
      pictogramsData = data;
    });
  }
// need to change await stuff to be outside the setstate, and then make it so that the images (when adding buttons) get added to firebase storage
  void addVisibleButtons(FirstButton button) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }

        final buttonId = Uuid().v4();
        final newButton = button.toJson()..['id'] = buttonId;

        nestedData.add(newButton);

        dataWidget.onDataChange(dataWidget.data);
        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });



    } else {
      print('DataWidget is null');
    }
  }

  Future<void> uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = imageFile.path.split('\\').last;
      Reference firebaseStorageRef = FirebaseStorage.instance.ref('initial_board_images/$fileName');
      SettableMetadata imageMetadata = SettableMetadata(
        contentType: 'image/png',
      );

      await firebaseStorageRef.putFile(imageFile, imageMetadata);

    } catch (e) {
      print("Error uploading image to firebase: $e");
    }
  }
  Future<void> saveImageLocally(File imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();

      // Manually extract the file name from the image path
      String fileName = imageFile.path.split('\\').last;

      // Create the local file path
      final String localPath = '${appDir.path}\\board_images\\$fileName';

      // Copy the file to the app's local directory
      await imageFile.copy(localPath);
    } catch (e) {
      print("Error saving image locally: $e");
    }
  }

  Future<void> downloadImageFromNetworkToLocalAndFirebase(String imageUrl) async {
    try {
      // Send a request to download the image
      final http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Get the application's documents directory
        final Directory appDir = await getApplicationDocumentsDirectory();

        // Extract the file name from the URL
        String fileName = imageUrl.split('/').last;

        // Create a local path to save the file
        final String localPath = '${appDir.path}\\board_images\\$fileName';

        // Write the downloaded image bytes to the local file
        File imageFile = File(localPath);
        await imageFile.writeAsBytes(response.bodyBytes);

        // Upload the image to Firebase Storage
        Reference firebaseStorageRef = FirebaseStorage.instance.ref('initial_board_images/$fileName');
        SettableMetadata imageMetadata = SettableMetadata(
          contentType: 'image/png',
        );
        await firebaseStorageRef.putFile(imageFile, imageMetadata);
      } else {
        print('Error downloading image: ${response.statusCode}');
      }
    } catch (e) {
      print("Error downloading image: $e");
    }

  }

  void addFolder(String folderName) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }


        final folderId = Uuid().v4();
        final newFolder = {
          "id": folderId,
          "image_url": "OneDrive_Folder_Icon.png",
          "label": folderName,
          "folder": true,
          "buttons": [],
        };


        nestedData.add(newFolder);


        dataWidget.onDataChange(dataWidget.data);


        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);


        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }

  Future<void> addCustomImageButton(String enteredText) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await uploadImageToFirebase(File(image.path));
      await saveImageLocally(File(image.path));
      FirstButton button = FirstButton(
        id: Uuid().v4(),
        imagePath: image.path.split('\\').last,
        text: enteredText,
        size: 60.0,
        onPressed: () {

        },
      );
      addVisibleButtons(button);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Stack(
        children: [SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: buttonColor,
          iconTheme: IconThemeData(color: iconColor),
          children: [
            SpeedDialChild(
              child: Icon(Icons.add, color: iconColor),
              backgroundColor: buttonColor,
              label: 'Add Button',
              onTap: () async {
                bool? choosePictogram = await _showChoiceDialog(context);
                if (choosePictogram == true) {
                  String? enteredText = await _showTextInputDialog(context, "Enter pictogram keyword:");
                  if (enteredText != null) {
                    dynamic buttonData = searchButtonData(pictogramsData, enteredText);
                    if (buttonData != null) {
                      setState(() {
                        _isUploading = true; // Start loading
                      });
                      FirstButton button = await _createFirstButtonFromData(buttonData, enteredText);
                      addVisibleButtons(button);
                      setState(() {
                        _isUploading = false; // Stop loading
                      });
                    } else {
                      bool? useCustomImage = await _showConfirmationDialog(context, "Pictogram not found. Would you like to upload a custom image?");
                      if (useCustomImage == true) {
                        await addCustomImageButton(enteredText);
                      }
                    }
                  }
                } else {
                  String? enteredText = await _showTextInputDialog(context, "Enter button label:");
                  if (enteredText != null) {
                    await addCustomImageButton(enteredText);
                  }
                }
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.create_new_folder, color: iconColor),
              backgroundColor: buttonColor,
              label: 'Add Folder',
              onTap: () async {
                String? folderName = await _showTextInputDialog(context, "Enter folder name:");
                if (folderName != null) {
                  addFolder(folderName);
                }
              },
            ),

          ],
          elevation: 0,
        ),
          if (_isUploading)
            Center(
              child: CircularProgressIndicator(), // Show loading spinner
            ),
      ]
    ),
    );
  }

  Future<bool?> _showChoiceDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Type'),
          content: Text('Would you like to search for a pictogram or upload a custom image?'),
          actions: <Widget>[
            TextButton(
              child: Text('Pictogram'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text('Custom Image'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  dynamic searchButtonData(List<dynamic> data, String keyword) {
    print(keyword);
    keyword = keyword.trim().toLowerCase();
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            print(item);
            return item;
          }
        }
      }
    }
    return null;
  }



  Future<FirstButton> _createFirstButtonFromData(Map<String, dynamic> data, String enteredText) async {
    String imageUrl = "https://static.arasaac.org/pictograms/${data['_id']}/${data['_id']}_2500.png";
    String label = enteredText;

    await downloadImageFromNetworkToLocalAndFirebase(imageUrl);

    return FirstButton(
      id: data["_id"].toString(),
      imagePath: imageUrl.split('/').last,
      text: label,
      size: 60.0,
      onPressed: () {

      },
    );
  }

  Future<String?> _showTextInputDialog(BuildContext context, String hintText) async {
    TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(hintText),
          content: TextField(
            controller: controller,
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
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}


class RemoveButton extends StatefulWidget {
  @override
  State<RemoveButton> createState() => RemoveButtonState();
}

class RemoveButtonState extends State<RemoveButton> {
  bool isRemovalMode = false;


  final Color buttonColor = Colors.lightBlue;
  final Color iconColor = Colors.white;
  final double buttonSize = 60.0;


  void addFolder(String folderName) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget != null) {
      setState(() {
        dynamic nestedData = dataWidget.data;

        for (var folder in pathWidget!.pathOfBoard) {
          nestedData = nestedData[folder];
        }


        final folderId = Uuid().v4();
        final newFolder = {
          "id": folderId,
          "image_url": "assets/imgs/OneDrive_Folder_Icon.png",
          "label": folderName,
          "folder": true,
          "buttons": [],
        };

        nestedData.add(newFolder);


        dataWidget.onDataChange(dataWidget.data);


        context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);


        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(16),
          backgroundColor: buttonColor,
          minimumSize: Size(buttonSize, buttonSize),
        ),
        onPressed: () {
          context.findAncestorStateOfType<HomePageState>()?.changeRemovalState();
          setState(() {
            isRemovalMode = !isRemovalMode;
          });
        },
        child: Icon(isRemovalMode ? Icons.check : Icons.delete, color: iconColor),
      ),
    );
  }
}