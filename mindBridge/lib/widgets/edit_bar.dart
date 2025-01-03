import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/fileUploadandDownLoad.dart';
import 'package:test_app/main.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'child_provider.dart';

import '../child_pages/home_page.dart';
import 'buttons.dart';
import 'package:path/path.dart' as path; // Import the path package
import 'globals.dart';

class EditBar extends StatelessWidget {
  final dynamic data;

  EditBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AddButton(data: data),
            RemoveButton(),
          ],
        ),
      ),
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
  //final Color buttonColor = Colors.lightBlue;
  // final Color iconColor = Colors.white;
  final double buttonSize = 70.0;

  List<dynamic> pictogramsData = [];
  final ImagePicker _picker = ImagePicker();
  var _isUploading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    String jsonString =
        await rootBundle.loadString('assets/board_info/pictograms.json');
    List<dynamic> data = jsonDecode(jsonString);
    setState(() {
      pictogramsData = data;
    });
  }

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
        context
            .findAncestorStateOfType<HomePageState>()
            ?.saveUpdatedData(dataWidget.data);
        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }

  /// Downloads an image, saves it locally with a `ChildId` directory structure, and uploads it to Firebase.
  Future<void> downloadImageFromNetworkToLocalAndFirebase(
      String imageUrl, String childId) async {
    try {
      // Fetch the image from the network
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Get the application documents directory
        final Directory appDir = await getApplicationDocumentsDirectory();

        // Extract the file name and build the local path with ChildId
        String fileName = path.basename(imageUrl); // Extract the file name
        final String localPath =
            path.join(appDir.path, childId, 'board_images', fileName);

        // Ensure the directory exists
        final Directory childDirectory =
            Directory(path.join(appDir.path, childId, 'board_images'));
        if (!await childDirectory.exists()) {
          await childDirectory.create(recursive: true);
          print('Created directory: ${childDirectory.path}');
        }

        // Save the image locally
        File imageFile = File(localPath);
        await imageFile.writeAsBytes(response.bodyBytes);

        print('Image downloaded and saved locally at $localPath');
        String firebasepath = 'user_folders/$childId/board_images/$fileName';

        // Upload the file to Firebase Storage using the refactored method
        final String firebaseImageUrl = await uploadFileToFirebase(
            response.bodyBytes, fileName, childId, firebasepath, false);

        print('Image uploaded to Firebase. Download URL: $firebaseImageUrl');

        // Assuming ChildProvider is a part of the context
        final childProvider =
            Provider.of<ChildProvider>(context, listen: false);
        String? childUsername = childProvider.childData?['username'];

        // Log the action with the child username and file name
        if (childUsername != null) {
          await logButtonAction(fileName, childUsername);
        } else {
          print('Child username is null. Skipping logButtonAction.');
        }
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

        context
            .findAncestorStateOfType<HomePageState>()
            ?.saveUpdatedData(dataWidget.data);

        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }
/*
  // Function to pick, upload, and save a custom image
  Future<void> addCustomImageButton(String enteredText) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final File imageFile = File(image.path);

        final childProvider =
            Provider.of<ChildProvider>(context, listen: false);
        String? childUsername = childProvider.childData?['username'];
        String? childId = childProvider.childId;
        print('childId: $childId');
            String fileName = path.basename(imageFile.path); // Extract file name

        // Upload the image to Firebase
        await uploadImageToFirebase(imageFile, fileName,childId!);


        await logButtonAction(fileName, childUsername!);

        // Save the image locally
        await saveImageLocally(imageFile, childId!);

        // Create a button and add it to the UI
        FirstButton button = FirstButton(
          id: Uuid().v4(),
          imagePath: path.basename(imageFile.path), // Use the file name
          text: enteredText,
          size: 60.0,
          onPressed: () {},
        );
        addVisibleButtons(button);

        print('Image successfully added with label: $enteredText');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print("Error in addCustomImageButton: $e");
    }
  }
*/

// Function to pick, upload, and save a custom image
  Future<void> addCustomImageToFirebaseAndLocal(
      String enteredText, String childId, String username) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final File imageFile = File(image.path);

        String fileName = path.basename(imageFile.path); // Extract file name
        String firebasepath = 'user_folders/$childId/board_images/$fileName';
        // Upload the image to Firebase using the refactored method
        String firebaseImageUrl = await uploadFileToFirebase(
            await imageFile.readAsBytes(),
            fileName,
            childId,
            firebasepath,
            false);

        print('Image uploaded to Firebase. URL: $firebaseImageUrl');

        // Log the action with the child username and file name

        await logButtonAction(fileName, username);

        // Save the image locally
        await saveImageLocally(imageFile, childId);

        // Create a button and add it to the UI
        FirstButton button = FirstButton(
          id: Uuid().v4(),
          imagePath: fileName, // Use the file name
          text: enteredText,
          size: 60.0,
          onPressed: () {},
        );
        addVisibleButtons(button);

        print('Image successfully added with label: $enteredText');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print("Error in addCustomImageButton: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ??
            theme.primaryColorDark;
    final buttonColor =
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
            theme.primaryColor;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Stack(
        children: [
          SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: buttonColor,
            buttonSize: const Size(70, 70),
            iconTheme: IconThemeData(color: iconColor), // Use theme for icon
            children: [
              SpeedDialChild(
                child: Icon(Icons.add, color: iconColor),
                backgroundColor: buttonColor,
                label: 'Add Button',
                onTap: () async {
                  final childProvider =
                      Provider.of<ChildProvider>(context, listen: false);
                  String? childUsername = childProvider.childData?['username'];
                  String? childId = childProvider.childId;
                  print('childId: $childId');

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    refreshGridFromLatestBoard(
                        context, childUsername!, childId!, false);
                  });

                  bool? choosePictogram = await _showChoiceDialog(context);
                  if (choosePictogram == true) {
                    String? enteredText = await _showTextInputDialog(
                        context, "Enter pictogram keyword:");
                    if (enteredText != null) {
                      dynamic buttonData =
                          searchButtonData(pictogramsData, enteredText);
                      if (buttonData != null) {
                        setState(() {
                          _isUploading = true;
                        });
                        final childProvider =
                            Provider.of<ChildProvider>(context, listen: false);

                        String? childId = childProvider.childId;
                        String? childUsername =
                            childProvider.childData?['username'];
                        print('childId: $childId');
                        FirstButton button = await _createFirstButtonFromData(
                            buttonData, enteredText, childId!);
                        addVisibleButtons(button);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Pictogram with title '$enteredText' has been added successfully to the board."),
                          ),
                        );

                        setState(() {
                          _isUploading = false;
                        });
                      } else {
                        bool? useCustomImage = await _showConfirmationDialog(
                            context,
                            "Pictogram not found. Would you like to upload a custom image?");
                        if (useCustomImage == true) {
                          await addCustomImageToFirebaseAndLocal(
                              enteredText, childId!, childUsername!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Custom image with title '$enteredText' has been added successfully to the board."),
                            ),
                          );
                        }
                      }
                    }
                  } else {
                    String? enteredText = await _showTextInputDialog(
                        context, "Enter button label:");
                    if (enteredText != null) {
                      await addCustomImageToFirebaseAndLocal(
                          enteredText, childId!, childUsername!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Custom image with title '$enteredText' has been added successfully to the board."),
                        ),
                      );
                    }
                  }
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.create_new_folder, color: iconColor),
                backgroundColor: buttonColor,
                label: 'Add Folder',
                onTap: () async {
                  String? folderName =
                      await _showTextInputDialog(context, "Enter folder name:");
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
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showChoiceDialog(BuildContext context) async {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              theme.dialogBackgroundColor, // Apply dialog background from theme
          titleTextStyle:
              theme.textTheme.headlineSmall, // Apply title text style
          contentTextStyle:
              theme.textTheme.bodyMedium, // Apply content text style
          title: Text('Choose Image Type',
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.elevatedButtonTheme.style?.backgroundColor
                      ?.resolve({}))),
          content: Text(
            'Would you like to search for a pictogram or upload a custom image?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Pictogram',
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text(
                'Custom Image',
              ),
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

  Future<FirstButton> _createFirstButtonFromData(
      Map<String, dynamic> data, String enteredText, String childId) async {
    String imageUrl =
        "https://static.arasaac.org/pictograms/${data['_id']}/${data['_id']}_2500.png";
    String label = enteredText;

    await downloadImageFromNetworkToLocalAndFirebase(imageUrl, childId);

    return FirstButton(
      id: data["_id"].toString(),
      imagePath: imageUrl.split('/').last,
      text: label,
      size: 60.0,
      onPressed: () {},
    );
  }

  Future<String?> _showTextInputDialog(
      BuildContext context, String hintText) async {
    TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titleTextStyle:
              theme.textTheme.headlineSmall, // Apply title text style
          contentTextStyle:
              theme.textTheme.bodyMedium, // Apply content text style
          title: Text(
            hintText,
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Type here",
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.secondary),
              ),
            ),
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

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String message) async {
    final theme = Theme.of(context);

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

  final double buttonSize = 70.0;

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

        context
            .findAncestorStateOfType<HomePageState>()
            ?.saveUpdatedData(dataWidget.data);

        context.findAncestorStateOfType<HomePageState>()?.updateGrid();
      });
    } else {
      print('DataWidget is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ??
            theme.primaryColorDark;
    final buttonColor =
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
            theme.primaryColor;
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: buttonColor,
          minimumSize: Size(buttonSize, buttonSize),
        ),
        onPressed: () {
          context
              .findAncestorStateOfType<HomePageState>()
              ?.changeRemovalState();
          setState(() {
            isRemovalMode = !isRemovalMode;
          });
        },
        child: Center(
            child: Icon(isRemovalMode ? Icons.check : Icons.delete,
                color: iconColor)),
      ),
    );
  }
}
