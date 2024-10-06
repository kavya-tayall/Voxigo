import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:test_app/widgets/child_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/auth_logic.dart';

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
      String? jsonData = await Provider.of<ChildProvider>(context, listen: false).fetchMusicJson();
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

  Future<void> _saveSongs(result) async {
    try {
      print("checkpoint1");
      // saving to local storage:
      final directory = await getApplicationDocumentsDirectory();
      print(directory.path);
      final musicDirectory = Directory('${directory.path}\\music_files\\');
      print(musicDirectory.path);

      final imageFileName = result['imageFile']!.path.split('\\').last;
      final newImageFilePath = '${musicDirectory.path}$imageFileName';
      final newImageFile = await result['imageFile']!.copy(newImageFilePath);
      print(imageFileName);
      print(newImageFilePath);
      print(newImageFile);


      final audioFileName = result['audioFile']!.path.split('\\').last;
      final newAudioFilePath = '${musicDirectory.path}$audioFileName';
      final newAudioFile = await result['audioFile']!.copy(newAudioFilePath);

      print(audioFileName);
      print(newAudioFilePath);
      print(newAudioFile);


      // saving to firebase:
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference musicRef = storage.ref('music_info/mp3 files/$audioFileName');
      SettableMetadata audioMetadata = SettableMetadata(
        contentType: 'audio/mpeg',
      );
      await musicRef.putFile(newAudioFile, audioMetadata);

      Reference coverImageRef = storage.ref('music_info/cover_images/$imageFileName');
      SettableMetadata imageMetadata = SettableMetadata(
        contentType: 'image/png',
      );
      await coverImageRef.putFile(newImageFile, imageMetadata);

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

        return titleLower.contains(searchLower) || keywordsLower.contains(searchLower);
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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Song'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Song Title'),
                    onChanged: (value) {
                      songTitle = value;
                    },
                  ),
                  SizedBox(height: 10),
                  if (imageFile != null)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Image.file(imageFile!, fit: BoxFit.cover),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );

                      if (result != null) {
                        setState(() {
                          imageFile = File(result.files.single.path!);
                        });
                      }
                    },
                    child: Text('Pick Image'),
                  ),
                  SizedBox(height: 10),
                  if (audioFile != null)
                    Text(
                      'Audio Selected: ${audioFile!.path.split('\\').last}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['mp3', 'wav'],
                      );

                      if (result != null) {
                        setState(() {
                          audioFile = File(result.files.single.path!);
                        });
                      }
                    },
                    child: Text('Pick Audio File'),
                  ),
                ],
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
                  onPressed: () {
                    if (songTitle != null && imageFile != null && audioFile != null) {
                      Navigator.of(context).pop({
                        'title': songTitle,
                        'imageFile': imageFile,
                        'audioFile': audioFile,
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result != null) {
        await _saveSongs(result);

        final newSong = Song(
          title: result['title'],
          emotion: ['unknown'],
          keywords: ['user', 'added'],
          link: result['audioFile']!.path.split('\\').last,
          image: result['imageFile']!.path.split('\\').last,
          isFromAssets: false,
        );
        _songs.add(newSong);
        await Provider.of<ChildProvider>(context, listen: false).changeMusicJson(_songs);

        // Now call setState to update the UI
        setState(() {
          _filteredSongs = List.from(_songs);
        });

        Future.delayed(Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Song added successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        );
      }
    });
  }

  void _deleteSong(int index) async {
    try {
      _songs.removeAt(index);
      setState(() {
        _filteredSongs = _songs;
      });
      await Provider.of<ChildProvider>(context, listen: false).changeMusicJson(_songs);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Song deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete song: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
      children: [
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
