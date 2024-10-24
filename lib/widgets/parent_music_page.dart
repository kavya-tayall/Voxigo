import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ParentMusicPage extends StatefulWidget {
  final String username;

  ParentMusicPage({required this.username});

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
    loadMusicData(widget.username);
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

  Future<void> loadMusicData(String username) async {
    try {
      String path = 'user_folders/$username/music.json';

      Reference storageRef = FirebaseStorage.instance.ref().child(path);
      String downloadUrl = await storageRef.getDownloadURL();

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          musicData = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
        for (var item in musicData) {
          fetchImageAndAudioUrls(item['image'], item['link']);
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

  Future<void> fetchImageAndAudioUrls(String imageName, String audioName) async {
    final imageUrl = await fetchImageFromStorage(imageName);
    final audioUrl = await fetchAudioFromStorage(audioName);

    print("Image URL: $imageUrl");
    print("Audio URL: $audioUrl");

    setState(() {
      imageUrlCache[imageName] = imageUrl;
      audioUrlCache[audioName] = audioUrl;
    });
  }


  Future<String> fetchImageFromStorage(String imageName) async {
    try {

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String localImagePath = '${appDocDir.path}/music_files/$imageName';


      File localFile = File(localImagePath);
      if (await localFile.exists()) {
        print("Loading image from local storage: $localImagePath");
        return localFile.path;
      } else {

        print("Image not found locally, downloading from Firebase...");
        String storagePath = 'music_info/cover_images/$imageName';
        Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
        String downloadUrl = await storageRef.getDownloadURL();


        var httpClient = HttpClient();
        var request = await httpClient.getUrl(Uri.parse(downloadUrl));
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(response);

        await localFile.writeAsBytes(bytes);

        return localFile.path;
      }
    } catch (e) {
      print("Error loading image for $imageName: $e");
      return '';
    }
  }

  Future<String> fetchAudioFromStorage(String audioName) async {
    try {

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String localAudioPath = '${appDocDir.path}/music_files/$audioName';


      File localFile = File(localAudioPath);
      if (await localFile.exists()) {
        print("Loading audio from local storage: $localAudioPath");
        return localFile.path;
      } else {

        print("Audio not found locally, downloading from Firebase...");
        String storagePath = 'music_info/mp3 files/$audioName';
        Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
        String downloadUrl = await storageRef.getDownloadURL();


        var httpClient = HttpClient();
        var request = await httpClient.getUrl(Uri.parse(downloadUrl));
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(response);

        await localFile.writeAsBytes(bytes);

        return localFile.path;
      }
    } catch (e) {
      print("Error loading audio for $audioName: $e");
      return '';
    }
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

  Future<void> addMusic() async {
    TextEditingController titleController = TextEditingController();
    PlatformFile? selectedImage;
    PlatformFile? selectedAudio;

    BuildContext dialogContext = context;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Music'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: 'Enter Music Title'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? imageResult = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (imageResult != null) {
                        setDialogState(() {
                          selectedImage = imageResult.files.first;
                        });
                      }
                    },
                    child: Text('Select Cover Image'),
                  ),
                  if (selectedImage != null)
                    Text('Image Selected: ${selectedImage!.name}', style: TextStyle(color: Colors.green)),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? audioResult = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['mp3', 'wav'],
                      );
                      if (audioResult != null) {
                        setDialogState(() {
                          selectedAudio = audioResult.files.first;
                        });
                      }
                    },
                    child: Text('Select Audio File'),
                  ),
                  if (selectedAudio != null)
                    Text('Audio Selected: ${selectedAudio!.name}', style: TextStyle(color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && selectedImage != null && selectedAudio != null) {
                      setState(() {
                        isUploading = true;
                      });
                      Navigator.of(dialogContext).pop();

                      await Future.microtask(() async {
                        String imagePath = 'music_info/cover_images/${selectedImage!.name}';
                        String audioPath = 'music_info/mp3 files/${selectedAudio!.name}';

                        await uploadFile(selectedImage!, imagePath);
                        await uploadFile(selectedAudio!, audioPath);

                        final imageUrl = await fetchImageFromStorage(selectedImage!.name);
                        final audioUrl = await fetchAudioFromStorage(selectedAudio!.name);

                        setState(() {
                          imageUrlCache[selectedImage!.name] = imageUrl;
                          audioUrlCache[selectedAudio!.name] = audioUrl;
                          musicData.add({
                            'title': titleController.text.trim(),
                            'emotion': [],
                            'keywords': [],
                            'link': selectedAudio!.name,
                            'image': selectedImage!.name,
                          });
                          isUploading = false;
                        });
                        await updateMusicJson();
                      });
                    } else {
                      print("Error: Missing title, image, or audio file");
                    }
                  },
                  child: Text('Add Song'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> uploadFile(PlatformFile file, String path) async {
    try {
      print("Debug: Attempting to upload to path: $path");


      Reference ref = FirebaseStorage.instance.ref().child(path);


      if (file.bytes != null) {
        print("Debug: Uploading file from memory: ${file.name}");


        await ref.putData(file.bytes!).then((taskSnapshot) {
          print("Debug: Upload completed: ${taskSnapshot.state}");
        });

      } else if (file.path != null) {

        final fileToUpload = File(file.path!);


        bool fileExists = await fileToUpload.exists();
        if (fileExists) {
          print("Debug: Uploading file from path: ${file.path}");


          await ref.putFile(fileToUpload).then((taskSnapshot) {
            print("Debug: Upload completed: ${taskSnapshot.state}");
          });
        } else {
          print("Error: File does not exist at path: ${file.path}");
          return;
        }

      } else {
        print("Error: No valid file source found for ${file.name}");
        return;
      }

      print("Success: File uploaded successfully to path: $path");

    } on FirebaseException catch (e) {


      print("Firebase Error: ${e.message}");
      print("Error Code: ${e.code}");

    } catch (e, stackTrace) {

      print("General Error: $e");
      print("Stack Trace: $stackTrace");
    }
  }



  Future<void> updateMusicJson() async {
    String path = 'user_folders/${widget.username}/music.json';
    Reference ref = FirebaseStorage.instance.ref().child(path);
    await ref.putString(jsonEncode(musicData));
  }

  Future<void> deleteMusic(int index) async {
    var musicItem = musicData[index];
    String imageName = musicItem['image'];
    String audioName = musicItem['link'];

    await deleteFile('music_info/cover_images/$imageName');
    await deleteFile('music_info/mp3 files/$audioName');


    musicData.removeAt(index);
    await updateMusicJson();
    setState(() {});
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Music List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addMusic,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: musicData.length,
        itemBuilder: (context, index) {
          final item = musicData[index];
          final imageUrl = imageUrlCache[item['image']] ?? '';
          final audioUrl = audioUrlCache[item['link']] ?? '';

          final isCurrentPlaying = currentAudioUrl == audioUrl;

          return Card(
            child: ListTile(
              leading: imageUrl.isNotEmpty
                  ? (imageUrl.startsWith('http') || imageUrl.startsWith('https'))
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
                    onPressed: () => deleteMusic(index),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}

