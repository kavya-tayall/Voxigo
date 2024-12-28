import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/getauthtokenandkey.dart';
import 'package:test_app/widgets/child_provider.dart';
import '../fileUploadandDownLoad.dart';

class ParentMusicPage extends StatefulWidget {
  final String username;
  final String childId;

  ParentMusicPage({required this.username, required this.childId});

  @override
  _ParentMusicPageState createState() => _ParentMusicPageState();
}

class _ParentMusicPageState extends State<ParentMusicPage> {
  List<Map<String, dynamic>> musicData = [];
  bool isLoading = true;
  AudioPlayer audioPlayer = AudioPlayer();
  String? currentAudioUrl;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isPlaying = false;

  Map<String, String> imageUrlCache = {};
  Map<String, String> audioUrlCache = {};

  @override
  void initState() {
    super.initState();
    loadMusicData(widget.username, widget.childId);
    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        currentAudioUrl = null;
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });
  }

  Future<void> loadMusicData(String username, String childId) async {
    try {
      String path = 'user_folders/$childId/music.json';

      Reference storageRef = FirebaseStorage.instance.ref().child(path);
      String downloadUrl = await storageRef.getDownloadURL();

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          musicData = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
        refreshMp3andCoverImages(childId, response.body, true);

        for (var item in musicData) {
          fetchImageAndAudioUrls(item['image'], item['link'], childId);
        }
      } else {
        print("Error: Could not fetch data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshMp3andCoverImages(
      String childId, String musicJsonString, bool forChild) async {
    final record = ChildCollectionWithKeys.instance.getRecord(childId);
    final String username = record?.username ?? 'defaultUsername';

    print(
        'Inside refreshMp3andCoverImages in parent login for child $username');

    // Fetch app installations for the user with MP3 parameter enabled
    QuerySnapshot<Object?>? appInstallationsSnapshot =
        await getAppInstallationsForUser(username, mp3: true);

    if (appInstallationsSnapshot == null) {
      print(
          'No app installation record found for this child and installation ID. Performing full  Mp3 refresh to create a new record.');

      // Copy music assets to local holder
      await copyMusicToLocalHolderFromAsset(childId);

      if (musicJsonString.isNotEmpty) {
        final List<dynamic> musicData = json.decode(musicJsonString);
        await downloadMp3FilesConcurrently(musicData, childId, username, true);
        return;
      } else {
        print('Failed to fetch or decode musicJsonString.');
      }
      return;
    }

    // Retrieve the timestamp from the first app installation document
    Timestamp appInstallationTimestamp =
        appInstallationsSnapshot.docs.first['timestamp'];

    // Process MP3 logs based on the retrieved timestamp
    processMP3Logs(username, childId, appInstallationTimestamp, forChild);
  }

  Future<void> fetchImageAndAudioUrls(
      String imageName, String audioName, String childId) async {
    final imageUrl =
        await fetchMP3CoverImageFromStorage(imageName, childId, true);
    final audioUrl = await fetchAudioFromStorage(audioName, childId, true);

    print("Image URL: $imageUrl");
    print("Audio URL: $audioUrl");

    setState(() {
      imageUrlCache[imageName] = imageUrl;
      audioUrlCache[audioName] = audioUrl;
    });
  }

  Future<void> playAudio(String audioUrl) async {
    if (currentAudioUrl == audioUrl && isPlaying) {
      audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      if (currentAudioUrl != audioUrl) {
        if (audioUrl.startsWith('http') || audioUrl.startsWith('https')) {
          await audioPlayer.play(UrlSource(audioUrl));
        } else {
          await audioPlayer.play(DeviceFileSource(audioUrl));
        }
        setState(() {
          currentAudioUrl = audioUrl;
          isPlaying = true;
        });
      } else {
        audioPlayer.resume();
        setState(() {
          isPlaying = true;
        });
      }
    }
  }

  Future<void> pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    setState(() {
      isPlaying = false;
      currentAudioUrl = null;
      currentPosition = Duration.zero;
    });
  }

  Future<void> seekAudio(Duration position) async {
    await audioPlayer.seek(position);
  }

  Future<void> rewindAudio() async {
    final newPosition = currentPosition - Duration(seconds: 10);
    await seekAudio(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> fastForwardAudio() async {
    final newPosition = currentPosition + Duration(seconds: 10);
    await seekAudio(newPosition > totalDuration ? totalDuration : newPosition);
  }

  bool isUploading = false;
  Future<void> addMusic(String childId) async {
    final TextEditingController titleController = TextEditingController();
    final FocusNode textFieldFocusNode = FocusNode();
    PlatformFile? selectedImage;
    PlatformFile? selectedAudio;
    bool isFilePickerActive = false;

    // Show the dialog
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Music'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    focusNode: textFieldFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Enter Music Title',
                      labelText: 'Music Title',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isFilePickerActive
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Please enter the music title before selecting a cover image.",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            textFieldFocusNode.unfocus();
                            isFilePickerActive = true;

                            FilePickerResult? imageResult = await FilePicker
                                .platform
                                .pickFiles(type: FileType.image);

                            if (imageResult != null) {
                              setDialogState(() {
                                selectedImage = imageResult.files.first;
                              });
                            }

                            isFilePickerActive = false;
                          },
                    child: Text('Select Cover Image'),
                  ),
                  if (selectedImage != null)
                    Text(
                      'Image Selected: ${selectedImage!.name}',
                      style: TextStyle(color: Colors.green),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isFilePickerActive
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Please enter the music title before selecting an audio file.",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            textFieldFocusNode.unfocus();
                            isFilePickerActive = true;

                            FilePickerResult? audioResult =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['mp3', 'wav'],
                            );

                            if (audioResult != null) {
                              setDialogState(() {
                                selectedAudio = audioResult.files.first;
                              });
                            }

                            isFilePickerActive = false;
                          },
                    child: Text('Select Audio File'),
                  ),
                  if (selectedAudio != null)
                    Text(
                      'Audio Selected: ${selectedAudio!.name}',
                      style: TextStyle(color: Colors.green),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ensure keyboard is dismissed
                    textFieldFocusNode.unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Ensure keyboard is dismissed
                    textFieldFocusNode.unfocus();

                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Please provide a title for the music before submitting.",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Please select a cover image to proceed.",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (selectedAudio == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Please select an audio file to proceed.",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    uploadMusic(
                      childId,
                      titleController.text.trim(),
                      selectedImage!,
                      selectedAudio!,
                    );
                  },
                  child: Text('Add Song'),
                ),
              ],
            );
          },
        );
      },
    );

    // Cleanup: Ensure keyboard is dismissed after dialog closes
    textFieldFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> uploadMusic(
    String childId,
    String title,
    PlatformFile imageFile,
    PlatformFile audioFile,
  ) async {
    setState(() {
      isUploading = true;
    });

    try {
      String imagePath =
          'user_folders/$childId/music_info/cover_images/${imageFile.name}';
      String audioPath =
          'user_folders/$childId/music_info/mp3 files/${audioFile.name}';

      await parentUploadMp3orCoverImageFileToFirebase(
          imageFile, imagePath, childId, true);
      await parentUploadMp3orCoverImageFileToFirebase(
          audioFile, audioPath, childId, true);

      logMp3Download(audioFile.name, imageFile.name, widget.username);

      final imageUrl =
          await fetchMP3CoverImageFromStorage(imageFile.name, childId, true);
      final audioUrl =
          await fetchAudioFromStorage(audioFile.name, childId, true);

      setState(() {
        imageUrlCache[imageFile.name] = imageUrl;
        audioUrlCache[audioFile.name] = audioUrl;
        musicData.add({
          'title': title,
          'emotion': [],
          'keywords': [],
          'link': audioFile.name,
          'image': imageFile.name,
        });
      });

      await updateMusicJson();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Music added successfully')),
      );
    } catch (e) {
      print("Error during upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add music')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> updateMusicJson() async {
    String path = 'user_folders/${widget.childId}/music.json';
    Reference ref = FirebaseStorage.instance.ref().child(path);
    await ref.putString(jsonEncode(musicData));
  }

  Future<void> deleteMusic(int index, String childId) async {
    var musicItem = musicData[index];
    String imageName = musicItem['image'];
    String audioName = musicItem['link'];

    // Show a confirmation dialog before deleting
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete this music file? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Do not delete
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Confirm delete
              },
            ),
          ],
        );
      },
    );

    // Proceed only if user confirms deletion
    if (shouldDelete == true) {
      try {
        // Deleting the files
        await deleteFile(
            'user_folders/$childId/music_info/cover_images/$imageName');
        await deleteFile(
            'user_folders/$childId/music_info/mp3 files/$audioName');

        // Removing the item from the music data list
        musicData.removeAt(index);

        // Updating the music JSON
        await updateMusicJson();

        setState(() {});

        // Notify the user of successful deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Music file deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete Music file: $e')),
        );
      }
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(path);
      await ref.delete();
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    return Scaffold(
      appBar: AppBar(
        title: Text('Music List'),
        actions: [
          Tooltip(
            message: isLoading
                ? 'Preparing your list'
                : isUploading
                    ? 'Uploading in progress'
                    : 'Add Music',
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: (isLoading || isUploading)
                  ? null
                  : () => addMusic(widget.childId),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!isLoading)
            ListView.builder(
              itemCount: musicData.length,
              itemBuilder: (context, index) {
                final item = musicData[index];
                final imageUrl = imageUrlCache[item['image']] ?? '';
                final audioUrl = audioUrlCache[item['link']] ?? '';

                final isCurrentPlaying = currentAudioUrl == audioUrl;

                return Card(
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? (imageUrl.startsWith('http') ||
                                imageUrl.startsWith('https'))
                            ? Image.network(imageUrl, width: 50, height: 50)
                            : Image.file(File(imageUrl), width: 50, height: 50)
                        : Icon(Icons.music_note),
                    title: Text(item['title']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(isCurrentPlaying && isPlaying
                              ? Icons.pause
                              : Icons.play_arrow),
                          onPressed: () => playAudio(audioUrl),
                        ),
                        IconButton(
                          icon: Icon(Icons.stop),
                          onPressed: stopAudio,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteMusic(index, widget.childId),
                        ),
                      ],
                    ),
                    subtitle: isCurrentPlaying
                        ? Column(
                            children: [
                              Slider(
                                value: currentPosition.inSeconds.toDouble(),
                                max: totalDuration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  seekAudio(Duration(seconds: value.toInt()));
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${currentPosition.inMinutes}:${currentPosition.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                  ),
                                  Text(
                                    "${totalDuration.inMinutes}:${totalDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.replay_10),
                                    onPressed: rewindAudio,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.forward_10),
                                    onPressed: fastForwardAudio,
                                  ),
                                ],
                              )
                            ],
                          )
                        : null,
                  ),
                );
              },
            )
          else
            Center(child: CircularProgressIndicator()),
          if (isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
