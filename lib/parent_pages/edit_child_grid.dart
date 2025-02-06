import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/getauthtokenandkey.dart';
import 'package:test_app/widgets/child_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:test_app/fileUploadandDownLoad.dart';
import 'package:test_app/widgets/globals.dart';

class ChildGridPage extends StatefulWidget {
  final String username;
  final String childId;
  final List<dynamic>? buttons;

  ChildGridPage({required this.username, required this.childId, this.buttons});

  @override
  _ChildGridPageState createState() => _ChildGridPageState();
}

class _ChildGridPageState extends State<ChildGridPage> {
  List<Map<String, dynamic>> gridData = [];
  List<String> currentFolderPath = [];
  bool isLoading = true;
  bool isRemovalMode = false;
  Directory? appDirectory;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> pictogramsData = [];

  @override
  void initState() {
    super.initState();
    loadAppDirectory();
    loadData();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    if (widget.buttons != null) {
      processBoardData(widget.buttons!);
    } else {
      fetchBoardInfoForChildGrid();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> loadAppDirectory() async {
    try {
      appDirectory = await getApplicationDocumentsDirectory();
    } catch (e) {
      print("Error loading app directory: $e");
    }
    setState(() {});
  }

  Future<void> loadData() async {
    String jsonString =
        await rootBundle.loadString('assets/board_info/pictograms.json');
    List<dynamic> data = jsonDecode(jsonString);
    setState(() {
      pictogramsData = data;
    });
  }

  Future<void> fetchBoardInfoForChildGrid() async {
    try {
      String path = 'user_folders/${widget.childId}/board.json';
      Reference storageRef = FirebaseStorage.instance.ref().child(path);
      String downloadUrl = await storageRef.getDownloadURL();

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> boardData = jsonDecode(response.body);
        processBoardData(boardData['buttons']);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void processBoardData(List<dynamic> buttons) async {
    List<Map<String, dynamic>> tempGridData = [];

    for (var button in buttons) {
      String imageFileName = button['image_url'];
      tempGridData.add({
        "image_url": imageFileName,
        "label": button['label'],
        "folder": button['folder'],
        "buttons": button['folder'] == true ? button['buttons'] : [],
        "id": button['id'],
      });
    }

    setState(() {
      gridData = tempGridData;
      isLoading = false;
    });
  }

  dynamic searchButtonData(List<dynamic> data, String keyword) {
    keyword = keyword.trim().toLowerCase();
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            return item;
          }
        }
      }
    }
    return null;
  }

  Future<void> addCustomImageOrPictorgramButton() async {
    bool? choosePictogram = await _showChoiceDialog(context);
    if (choosePictogram == true) {
      String? enteredText = await showButtonOrFolderTextInputDialog(
          context, "Enter button label:");
      // await _showTextInputDialog(context, "Enter button label:");

      if (enteredText == null) {
        return;
      }

      dynamic buttonData = searchButtonData(pictogramsData, enteredText);
      if (buttonData != null) {
        await _createFirstButtonFromData(
            buttonData, enteredText, widget.childId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Pictogram with title '$enteredText' has been added successfully to the board."),
          ),
        );
      } else {
        await _showConfirmationDialog(context,
            "Pictogram not found. Would you like to upload a custom image?");
        await uploadCustomImage(enteredText, widget.childId, widget.username);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Custom image with title '$enteredText' has been added successfully to the board."),
          ),
        );
      }
    } else {
      String? enteredText = await showButtonOrFolderTextInputDialog(
          context, "Enter button label:");
      if (enteredText == null) {
        return;
      }
      await uploadCustomImage(enteredText, widget.childId, widget.username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Custom image with title '$enteredText' has been added successfully to the board."),
        ),
      );
    }
  }

/*
  Future<void> uploadCustomImage(String enteredText, String childId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        String fileName = Uuid().v4();

        // Construct local path with childId
        final localImageDir =
            Directory(path.join(appDirectory!.path, childId, 'board_images'));
        if (!await localImageDir.exists()) {
          await localImageDir.create(recursive: true);
        }
        final localImagePath = path.join(localImageDir.path, '$fileName.png');
        final localImage = File(localImagePath);
        await localImage.writeAsBytes(await image.readAsBytes());

        // Construct Firebase path with childId
        Reference firebaseStorageRef = FirebaseStorage.instance
            .ref('user_folders/$childId/board_images/$fileName');
        await firebaseStorageRef.putFile(File(image.path));
        String childusername =
            ChildCollectionWithKeys.instance.getRecord(childId)?.username ?? '';
        await logButtonAction(fileName, childusername);

        // Update folder structure locally
        Map<String, dynamic> currentFolder = getCurrentFolder();
        setState(() {
          currentFolder['buttons'].add({
            "id": Uuid().v4(),
            "image_url": fileName,
            "label": enteredText,
            "folder": false,
            "buttons": [],
          });
        });

        // Update board in Firebase
        await updateBoardInFirebase(widget.childId, gridData);
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }*/

  Future<void> uploadCustomImage(
      String enteredText, String childId, String username,
      {bool forChild = true}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
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

        // Update folder structure locally
        Map<String, dynamic> currentFolder = getCurrentFolder();
        setState(() {
          currentFolder['buttons'].add({
            "id": Uuid().v4(),
            "image_url": fileName, // Use Firebase image URL
            "label": enteredText,
            "folder": false,
            "buttons": [],
          });
        });

        // Update board in Firebase
        await updateBoardInFirebase(widget.childId, gridData);
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  Future<void> _createFirstButtonFromData(
      Map<String, dynamic> data, String enteredText, String childId) async {
    try {
      String imageUrl =
          "https://static.arasaac.org/pictograms/${data['_id']}/${data['_id']}_2500.png";

      http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        String fileName = Uuid().v4();

        // Call the extracted method to handle file upload to Firebase
        String firebasepath = 'user_folders/$childId/board_images/$fileName';
        String firebaseImageUrl = await uploadFileToFirebase(
            response.bodyBytes, fileName, childId, firebasepath, true);
        String childusername =
            ChildCollectionWithKeys.instance.getRecord(childId)?.username ?? '';
        await logButtonAction(fileName, childusername);

        Map<String, dynamic> currentFolder = getCurrentFolder();

        setState(() {
          currentFolder['buttons'].add({
            "id": data["_id"].toString(),
            "image_url": fileName,
            "label": enteredText,
            "folder": false,
            "buttons": [],
          });
        });

        await updateBoardInFirebase(widget.childId, gridData);
      } else {
        throw Exception('Error downloading pictogram image');
      }
    } catch (e) {
      print("Error creating pictogram button: $e");
    }
  }

  Map<String, dynamic> getCurrentFolder() {
    Map<String, dynamic> currentFolder = {"buttons": gridData};
    for (var folderId in currentFolderPath) {
      currentFolder = currentFolder['buttons']
          .firstWhere((folder) => folder['id'] == folderId);
    }
    return currentFolder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}\'s Grid'),
        actions: [
          IconButton(
            icon: Icon(isRemovalMode ? Icons.check : Icons.delete),
            onPressed: () {
              setState(() {
                isRemovalMode = !isRemovalMode;
              });
            },
          ),
          if (currentFolderPath.isNotEmpty)
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: navigateBack,
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gridData.isEmpty
              ? Center(child: Text("No data found for this child"))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 75.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: getCurrentFolder()['buttons'].length,
                    itemBuilder: (context, index) {
                      final item = getCurrentFolder()['buttons'][index];
                      final imageFileName = item['image_url'];
                      final imageUrlFuture = fetchBoardImageFromStorage(
                          imageFileName, widget.childId, true);

                      return FutureBuilder(
                        future: imageUrlFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text("Error loading image"));
                          } else if (!snapshot.hasData || snapshot.data == '') {
                            return Center(child: Text("Image not found"));
                          }

                          return GestureDetector(
                            onTap: isRemovalMode
                                ? () {
                                    String itemType = (item['folder'] == true)
                                        ? 'folder'
                                        : 'button';
                                    removeButton(
                                        itemType, index, widget.childId);
                                  }
                                : () {
                                    if (item['folder'] == true) {
                                      setState(() {
                                        currentFolderPath.add(item['id']);
                                      });
                                    } else {}
                                  },
                            child: GridTile(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 150.0,
                                      child: Image.file(
                                        File(snapshot.data!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10.0),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item['label'] ?? '',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 9),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Button',
            onTap: () async {
              await addCustomImageOrPictorgramButton();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.folder),
            label: 'Add Folder',
            onTap: () async {
              /* String? folderName = await _showTextInputDialog(context, "Enter folder name:");*/

              String? folderName = await showButtonOrFolderTextInputDialog(
                  context, "Enter folder name:");
              if (folderName != null) {
                Map<String, dynamic> currentFolder = getCurrentFolder();

                setState(() {
                  currentFolder['buttons'].add({
                    "id": Uuid().v4(),
                    "image_url": "OneDrive_Folder_Icon.png",
                    "label": folderName,
                    "folder": true,
                    "buttons": [],
                  });
                });

                await updateBoardInFirebase(widget.childId, gridData);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showChoiceDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Type'),
          content: Text(
              'Would you like to search for a pictogram or upload a custom image?'),
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

  Future<String?> _showTextInputDialog(
      BuildContext context, String title) async {
    TextEditingController _textFieldController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface, // Themed background color
          title: Text(
            title,
            style: theme.textTheme.headlineSmall, // Themed title style
          ),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(
              hintText: "Enter your input here 1",
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor, // Themed hint color
              ),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: theme.dividerColor), // Themed border
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: theme.colorScheme.primary), // Themed focus border
              ),
            ),
            style: theme.textTheme.bodyMedium, // Themed input text style
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.primary, // Themed action color
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.primary, // Themed action color
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(_textFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void navigateBack() {
    setState(() {
      if (currentFolderPath.isNotEmpty) {
        currentFolderPath.removeLast();
      }
    });
  }

  void removeButton(String itemType, int index, String childId) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            itemType == "folder" ? "Delete Folder" : "Delete Button",
            style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.elevatedButtonTheme.style?.backgroundColor
                    ?.resolve({})),
          ),
          content: Text(
            itemType == "folder"
                ? "Are you sure you want to delete this folder and all its contents?"
                : "Are you sure you want to delete this button?",
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme
                    .elevatedButtonTheme.style?.backgroundColor
                    ?.resolve({}),
              ),
              child: const Text(
                "Cancel",
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        getCurrentFolder()['buttons'].removeAt(index);
      });
      updateBoardInFirebase(childId, gridData);
      print("$itemType with index $index removed for child ID $childId.");
    } else {
      print("$itemType deletion canceled by the user.");
    }
  }
}
