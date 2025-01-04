import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/widgets/child_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/music_tile.dart';
import '../fileUploadandDownLoad.dart';

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
  FocusNode _focusNode = FocusNode();
  bool isLoading = true;
  bool _isRebuilding = false; // New loading state for list rebuilding

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    //fetch and process music.json
    String childId =
        Provider.of<ChildProvider>(context, listen: false).childId!;
    fetchMusicFiles(context, childId, false);
    _loadSongsOld();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSongsOld() async {
    try {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      String? childId = childProvider.childId;

      String? jsonData =
          await Provider.of<ChildProvider>(context, listen: false)
              .fetchJson('music.json', childId!);

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

  Future<void> _saveSongsAndUpload(
      Map<String, dynamic> result, String childId) async {
    try {
      // Save to local storage with childId in the directory path
      final directory = await getApplicationDocumentsDirectory();
      final musicInfoDirectory =
          Directory(path.join(directory.path, childId, 'music_info'));

      // Subfolders for cover images and mp3 files
      final coverImagesDirectory =
          Directory(path.join(musicInfoDirectory.path, 'cover_images'));
      final mp3FilesDirectory =
          Directory(path.join(musicInfoDirectory.path, 'mp3 files'));

      // Create directories if they don't exist
      if (!(await coverImagesDirectory.exists())) {
        await coverImagesDirectory.create(recursive: true);
      }
      if (!(await mp3FilesDirectory.exists())) {
        await mp3FilesDirectory.create(recursive: true);
      }

      // Save image locally
      final imageFile = result['imageFile'] as File;
      final imageFileName = path.basename(imageFile.path);
      final newImageFilePath =
          path.join(coverImagesDirectory.path, imageFileName);
      await imageFile.copy(newImageFilePath);

      // Save audio locally
      final audioFile = result['audioFile'] as File;
      final audioFileName = path.basename(audioFile.path);
      final newAudioFilePath = path.join(mp3FilesDirectory.path, audioFileName);
      await audioFile.copy(newAudioFilePath);

      // Upload to Firebase with childId in the path
      await uploadMP3OrCoverImageFile(
          imageFile,
          'user_folders/$childId/music_info/cover_images/$imageFileName',
          childId,
          imageFileName,
          false);
      await uploadMP3OrCoverImageFile(
          audioFile,
          'user_folders/$childId/music_info/mp3 files/$audioFileName',
          childId,
          audioFileName,
          false);
      String username = Provider.of<ChildProvider>(context, listen: false)
          .childData!['username'];
      logMp3Download(audioFileName, imageFileName, username);
    } catch (e) {
      print('Error saving and uploading music: $e');
    }
  }

  Future<void> _saveSongs(Map<String, dynamic> result, String childId) async {
    try {
      // Get the base application directory
      final directory = await getApplicationDocumentsDirectory();

      // Build the base music_info directory path
      final musicInfoDirectory =
          Directory(path.join(directory.path, childId, 'music_info'));

      // Define subdirectories for cover images and mp3 files
      final coverImagesDirectory =
          Directory(path.join(musicInfoDirectory.path, 'cover_images'));
      final mp3FilesDirectory =
          Directory(path.join(musicInfoDirectory.path, 'mp3 files'));

      // Ensure directories exist
      if (!(await coverImagesDirectory.exists())) {
        await coverImagesDirectory.create(recursive: true);
      }
      if (!(await mp3FilesDirectory.exists())) {
        await mp3FilesDirectory.create(recursive: true);
      }

      // Save the image file to the cover_images subdirectory
      final imageFile = result['imageFile'] as File;
      final imageFileName = path.basename(imageFile.path);
      final newImageFilePath =
          path.join(coverImagesDirectory.path, imageFileName);
      await imageFile.copy(newImageFilePath);

      // Save the audio file to the mp3 files subdirectory
      final audioFile = result['audioFile'] as File;
      final audioFileName = path.basename(audioFile.path);
      final newAudioFilePath = path.join(mp3FilesDirectory.path, audioFileName);
      await audioFile.copy(newAudioFilePath);

      print('Files saved successfully to $musicInfoDirectory');
    } catch (e) {
      print('Error saving music to local storage: $e');
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

  void _deleteSong(int index) async {
    try {
      _songs.removeAt(index);
      setState(() {
        _filteredSongs = _songs;
      });
      await Provider.of<ChildProvider>(context, listen: false).changeMusicJson(
          _songs, Provider.of<ChildProvider>(context, listen: false).childId!);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Song deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete song: $e')));
    }
  }

  Future<void> _addMusic(BuildContext context) async {
    String? songTitle;
    File? imageFile;
    File? audioFile;
    bool isFilePickerActive = false;

    final parentContext = context;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Add Music'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter Music Title',
                        labelText: 'Music Title',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        songTitle = value;
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isFilePickerActive
                          ? null
                          : () async {
                              FocusScope.of(dialogContext).unfocus();
                              setDialogState(() {
                                isFilePickerActive = true;
                              });

                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );

                              if (result != null) {
                                setDialogState(() {
                                  imageFile = File(result.files.single.path!);
                                });
                              }

                              setDialogState(() {
                                isFilePickerActive = false;
                              });
                            },
                      child: Text('Select Cover Image'),
                    ),
                    if (imageFile != null)
                      Text('Image Selected: ${path.basename(imageFile!.path)}'),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isFilePickerActive
                          ? null
                          : () async {
                              FocusScope.of(dialogContext).unfocus();
                              setDialogState(() {
                                isFilePickerActive = true;
                              });

                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['mp3', 'wav'],
                              );

                              if (result != null) {
                                setDialogState(() {
                                  audioFile = File(result.files.single.path!);
                                });
                              }

                              setDialogState(() {
                                isFilePickerActive = false;
                              });
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
                  child: Text('Add Music'),
                  onPressed: () async {
                    FocusScope.of(dialogContext).unfocus();

                    if (songTitle == null || songTitle!.trim().isEmpty) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid music title.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    if (imageFile == null) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Please select a cover image.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    if (audioFile == null) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Please select an audio file.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    showDialog(
                      context: parentContext,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Expanded(
                                child: Text('Uploading files, please wait...'),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    try {
                      await _saveSongsAndUpload(
                        {
                          'title': songTitle,
                          'imageFile': imageFile,
                          'audioFile': audioFile,
                        },
                        Provider.of<ChildProvider>(parentContext, listen: false)
                            .childId!,
                      );

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
                        });
                      }

                      await Provider.of<ChildProvider>(parentContext,
                              listen: false)
                          .changeMusicJson(
                        _songs,
                        Provider.of<ChildProvider>(parentContext, listen: false)
                            .childId!,
                      );

                      Navigator.of(parentContext)
                          .pop(); // Dismiss progress dialog
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Music added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(parentContext)
                          .pop(); // Dismiss progress dialog
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Error adding music: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
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

/*
  void deleteSong(int index) async {
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

        await deleteFile(index);

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
  */

/*   void _deleteSong(int index) async {
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
  }*/

  Future<void> deleteFile(int index) async {
    try {
      // Remove the song and update state
      _songs.removeAt(index);
      setState(() {
        _filteredSongs = _songs;
      });

      // Update the provider
      await Provider.of<ChildProvider>(context, listen: false).changeMusicJson(
        _songs,
        Provider.of<ChildProvider>(context, listen: false).childId!,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Music file deleted successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete music file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;
    final isSmallDevice = mediaQuery.size.width < 350;
    final theme = Theme.of(context); // Access the current theme
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isMobile = screenWidth < 600;

    void _dismissKeyboard() {
      FocusScope.of(context).requestFocus(FocusNode());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Music & Stories'),
        automaticallyImplyLeading:
            true, // Ensures a back button if there is a previous route
        leading: Provider.of<ChildProvider>(context, listen: false)
                    .childNavigateFrom ==
                "feelings"
            ? BackButton(onPressed: () {
                Navigator.pop(
                    context); // Pops the current route from the navigation stack
                Provider.of<ChildProvider>(context, listen: false)
                    .childNavigateFrom = "";
              })
            : null, // If there's no route to pop, leading is null
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(
                    12.0), // Ensure padding around all content
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [],
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by title or keyword',
                          labelStyle: isMobile
                              ? TextStyle(
                                  fontSize: 16, color: theme.primaryColor)
                              : TextStyle(
                                  fontSize: 18, color: theme.primaryColor),
                          filled: true,
                          prefixIcon:
                              Icon(Icons.search, color: theme.primaryColor),
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
                    SizedBox(height: 10),
                    // Check if the song list is empty or not
                    if (_filteredSongs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(
                          child: Text(
                            'No Music file found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      // Use ListView.builder inside the scroll view
                      Scrollbar(
                        controller: _scrollController,
                        thickness: 6.0,
                        radius: Radius.circular(10),
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          primary: false,
                          shrinkWrap:
                              true, // This ensures ListView takes only as much space as it needs
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 5.0),
                              child: MusicTile(
                                index: index,
                                song: _filteredSongs[index],
                                onPlayPause: _onPlayPause,
                                isPlaying: _currentlyPlayingIndex == index,
                                onDelete: _deleteSong,
                              ),
                            );
                          },
                        ),
                      ),
                    // Add Music Button
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton(
                        onPressed: () => _addMusic(context),
                        child: Text('Add Music from Files'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(
                            isTablet ? 250 : 180,
                            isTablet ? 50 : 40,
                          ),
                          textStyle: TextStyle(
                              fontSize: isTablet ? 18 : 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
