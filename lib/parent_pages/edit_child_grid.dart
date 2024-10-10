import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChildGridPage extends StatefulWidget {
  final String username;
  final List<dynamic>? buttons;

  ChildGridPage({required this.username, this.buttons});

  @override
  _ChildGridPageState createState() => _ChildGridPageState();
}

class _ChildGridPageState extends State<ChildGridPage> {
  List<Map<String, dynamic>> gridData = [];
  bool isLoading = true;
  bool isRemovalMode = false; // To track removal mode
  Directory? appDirectory;

  @override
  void initState() {
    super.initState();
    loadAppDirectory();
    if (widget.buttons != null) {
      processBoardData(widget.buttons!);
    } else {
      fetchBoardInfo();
    }
  }

  Future<void> loadAppDirectory() async {
    try {
      appDirectory = await getApplicationDocumentsDirectory();
    } catch (e) {
      print("Error loading app directory: $e");
    }
    setState(() {});
  }

  Future<void> fetchBoardInfo() async {
    try {
      String path = 'user_folders/${widget.username}/board.json';
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
      // Don't fetch the URL, use the stored image file name
      String imageFileName = button['image_url'];
      tempGridData.add({
        "image_url": imageFileName,  // Store just the file name
        "label": button['label'],
        "folder": button['folder'],
        "buttons": button['buttons'],
        "id": button['id'],
      });
    }

    setState(() {
      gridData = tempGridData;
      isLoading = false;
    });
  }

  Future<String> fetchImageFromStorage(String imageName) async {
    try {
      String storagePath = 'initial_board_images/$imageName';
      Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return '';
    }
  }

  void addFolder(String folderName) {
    setState(() {
      final newFolder = {
        "id": Uuid().v4(),
        "image_url": "OneDrive_Folder_Icon.png",
        "label": folderName,
        "folder": true,
        "buttons": [],
      };
      gridData.add(newFolder);
    });
  }

  Future<void> addCustomImageButton(String enteredText) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        String fileName = Uuid().v4(); // Generate a unique file name
        Reference firebaseStorageRef = FirebaseStorage.instance.ref('initial_board_images/$fileName');

        // Use File(image.path) correctly to upload the image
        await firebaseStorageRef.putFile(File(image.path));

        String imageUrl = await firebaseStorageRef.getDownloadURL();

        setState(() {
          gridData.add({
            "id": Uuid().v4(),
            "image_url": fileName, // Store just the image file name in the gridData
            "label": enteredText,
            "folder": false,
            "buttons": [],
          });
        });

        await updateBoardInFirebase(); // Make sure to update Firebase after adding the button
      } catch (e) {
        print("Error uploading image: $e");
        // You can also show a message to the user in case of error
      }
    }
  }


  Future<void> updateBoardInFirebase() async {
    try {
      String path = 'user_folders/${widget.username}/board.json';
      Reference storageRef = FirebaseStorage.instance.ref().child(path);

      // Convert gridData to JSON, ensuring only file names are stored
      Map<String, dynamic> boardData = {
        "buttons": gridData,
      };

      // Upload the updated data to Firebase
      await storageRef.putString(jsonEncode(boardData), metadata: SettableMetadata(contentType: 'application/json'));
    } catch (e) {
      print("Error updating board in Firebase: $e");
    }
  }



  void removeButton(String buttonId) {
    setState(() {
      gridData.removeWhere((button) => button['id'] == buttonId);
    });

    updateBoardInFirebase();
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
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gridData.isEmpty
          ? Center(child: Text("No data found for this child"))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: gridData.length,
            itemBuilder: (context, index) {
              final item = gridData[index];
              final imageFileName = item['image_url']; // This is just the file name
              final label = item['label'];
              final isFolder = item['folder'] ?? false;
              final buttons = item['buttons'] ?? [];

              return FutureBuilder<String>(
                future: fetchImageFromStorage(imageFileName), // Fetch the full URL here
                builder: (context, snapshot) {
                  return GestureDetector(
                    onTap: () {
                      if (isFolder && buttons.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildGridPage(
                              username: widget.username,
                              buttons: buttons,
                            ),
                          ),
                        );
                      } else if (isRemovalMode) {
                        removeButton(item['id']);
                      }
                    },
                    child: GridTile(
                      child: Column(
                        children: [
                          Expanded(
                            child: snapshot.hasData
                                ? Image.network(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            )
                                : Icon(Icons.broken_image),
                          ),
                          SizedBox(height: 8),
                          Text(label),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Button',
            onTap: () async {
              String? enteredText = await _showTextInputDialog(context, "Enter button label:");
              if (enteredText != null) {
                await addCustomImageButton(enteredText);
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.create_new_folder),
            label: 'Add Folder',
            onTap: () async {
              String? folderName = await _showTextInputDialog(context, "Enter folder name:");
              if (folderName != null) {
                addFolder(folderName);
              }
            },
          ),
        ],
      ),
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
}
