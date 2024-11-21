import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:test_app/widgets/child_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/music_tile.dart';

class MusicPage extends StatefulWidget {
  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  AudioPlayer? _currentlyPlayingPlayer;
  int? _currentlyPlayingIndex;
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  bool _isRebuilding = false; // New loading state for list rebuilding

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSongsOld();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSongsOld() async {
    try {
      String? jsonData =
      await Provider.of<ChildProvider>(context, listen: false)
          .fetchJson('music.json');
      final List<dynamic> data = json.decode(jsonData!);
      setState(() {
        _songs = data.map((json) => Song.fromJson(json)).toList();
        _filteredSongs = _songs;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading songs: $e');
    }
  }

  Future<void> _saveSongsAndUpload(Map<String, dynamic> result) async {
    try {
      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final musicDirectory =
      Directory(path.join(directory.path, 'music_files'));

      if (!(await musicDirectory.exists())) {
        await musicDirectory.create(recursive: true);
      }

      // Save image locally
      final imageFile = result['imageFile'] as File;
      final imageFileName = path.basename(imageFile.path);
      final newImageFilePath = path.join(musicDirectory.path, imageFileName);
      await imageFile.copy(newImageFilePath);

      // Save audio locally
      final audioFile = result['audioFile'] as File;
      final audioFileName = path.basename(audioFile.path);
      final newAudioFilePath = path.join(musicDirectory.path, audioFileName);
      await audioFile.copy(newAudioFilePath);

      // Upload to Firebase
      await _uploadFile(imageFile, 'music_info/cover_images/$imageFileName');
      await _uploadFile(audioFile, 'music_info/mp3 files/$audioFileName');
    } catch (e) {
      print('Error saving and uploading songs: $e');
    }
  }

  Future<void> _uploadFile(File file, String path) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);
    } catch (e) {
      print("Error uploading file to Firebase: $e");
    }
  }

  Future<void> _saveSongs(result) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final musicDirectory =
      Directory(path.join(directory.path, 'music_files'));

      if (!(await musicDirectory.exists())) {
        await musicDirectory.create(recursive: true);
      }

      final imageFile = result['imageFile']!;
      final imageFileName = path.basename(imageFile.path);
      final newImageFilePath = path.join(musicDirectory.path, imageFileName);
      final newImageFile = await imageFile.copy(newImageFilePath);

      final audioFile = result['audioFile']!;
      final audioFileName = path.basename(audioFile.path);
      final newAudioFilePath = path.join(musicDirectory.path, audioFileName);
      final newAudioFile = await audioFile.copy(newAudioFilePath);
    } catch (e) {
      print('Error saving songs to local storage: $e');
    }
  }

  void _onPlayPause(int index, AudioPlayer audioPlayer) async {
    if (_currentlyPlayingIndex != null && _currentlyPlayingIndex != index) {
      _currentlyPlayingPlayer?.stop();
    }

    setState(() {
      _currentlyPlayingIndex = index;
      _currentlyPlayingPlayer = audioPlayer;
    });
  }

  void _searchSongs(String query) {
    setState(() {
      _filteredSongs = _songs.where((song) {
        final titleLower = song.title.toLowerCase();
        final keywordsLower = song.keywords.join(' ').toLowerCase();
        final searchLower = query.toLowerCase();

        return titleLower.contains(searchLower) ||
            keywordsLower.contains(searchLower);
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredSongs = _songs;
    });
  }

  Future<void> _addMusic(BuildContext context) async {
    String? songTitle;
    File? imageFile;
    File? audioFile;

    // Capture parent context for safe operations
    final parentContext = context;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Add New Song'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Song Title'),
                      onChanged: (value) {
                        songTitle = value;
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null) {
                          if (mounted) {
                            setDialogState(() {
                              imageFile = File(result.files.single.path!);
                            });
                          }
                        }
                      },
                      child: Text('Select Cover Image'),
                    ),
                    if (imageFile != null)
                      Text('Image Selected: ${path.basename(imageFile!.path)}'),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['mp3', 'wav'],
                        );
                        if (result != null) {
                          if (mounted) {
                            setDialogState(() {
                              audioFile = File(result.files.single.path!);
                            });
                          }
                        }
                      },
                      child: Text('Select Audio File'),
                    ),
                    if (audioFile != null)
                      Text('Audio Selected: ${path.basename(audioFile!.path)}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add Song'),
                  onPressed: () async {
                    if (songTitle != null &&
                        imageFile != null &&
                        audioFile != null) {
                      Navigator.of(context).pop();

                      // Show Progress Dialog
                      String progressMessage = 'Starting upload...';
                      showDialog(
                        context: parentContext,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Expanded(child: Text(progressMessage)),
                              ],
                            ),
                          );
                        },
                      );

                      try {
                        // Save and upload files
                        progressMessage = 'Uploading files...';
                        await _saveSongsAndUpload({
                          'title': songTitle,
                          'imageFile': imageFile,
                          'audioFile': audioFile,
                        });

                        // Show rebuilding progress
                        if (mounted) {
                          Navigator.of(parentContext)
                              .pop(); // Dismiss progress dialog
                          setState(() {
                            _isRebuilding = true;
                          });
                        }

                        // Simulate list rebuilding
                        await Future.delayed(
                            Duration(seconds: 2)); // Simulated delay

                        final newSong = Song(
                          title: songTitle!,
                          emotion: ['unknown'],
                          keywords: ['user', 'added'],
                          link: path.basename(audioFile!.path),
                          image: path.basename(imageFile!.path),
                          isFromAssets: false,
                        );

                        if (mounted) {
                          setState(() {
                            _songs.add(newSong);
                            _filteredSongs = List.from(_songs);
                            _isRebuilding = false; // Rebuilding complete
                          });
                        }

                        await Provider.of<ChildProvider>(parentContext,
                            listen: false)
                            .changeMusicJson(_songs);

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text('Song added successfully!')),
                        );
                      } catch (e) {
                        print('Error adding song: $e');
                        if (mounted) {
                          Navigator.of(parentContext)
                              .pop(); // Dismiss progress dialog
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text('Error adding song: $e')),
                          );
                        }
                      }
                    } else {
                      print('Error: Missing required fields.');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSong(int index) async {
    try {
      _songs.removeAt(index);
      setState(() {
        _filteredSongs = _songs;
      });
      await Provider.of<ChildProvider>(context, listen: false)
          .changeMusicJson(_songs);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Song deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete song: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Music & Stories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 80 : 60,
                        color: Colors.blueAccent,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 4.0),
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by title or keyword',
                    filled: true,
                    fillColor: Colors.blue[50],
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  onChanged: (query) {
                    _searchSongs(query);
                  },
                ),
              ),
              Expanded(
                child: _filteredSongs.isEmpty
                    ? Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : Scrollbar(
                  controller: _scrollController,
                  thickness: 8.0,
                  radius: Radius.circular(20),
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    primary: false,
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      return MusicTile(
                        index: index,
                        song: _filteredSongs[index],
                        onPlayPause: _onPlayPause,
                        isPlaying: _currentlyPlayingIndex == index,
                        onDelete: _deleteSong,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _addMusic(context),
                      child: Text('Add Song from Files'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isRebuilding)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Updating List...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class Song {
  final String title;
  final List<String> emotion;
  final List<String> keywords;
  final String link;
  final String image;
  final bool isFromAssets;

  Song({
    required this.title,
    required this.emotion,
    required this.keywords,
    required this.link,
    required this.image,
    this.isFromAssets = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'],
      emotion: List<String>.from(json['emotion']),
      keywords: List<String>.from(json['keywords']),
      link: json['link'],
      image: json['image'],
      isFromAssets: json['isFromAssets'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'emotion': emotion,
      'keywords': keywords,
      'link': link,
      'image': image,
      'isFromAssets': isFromAssets,
    };
  }
}