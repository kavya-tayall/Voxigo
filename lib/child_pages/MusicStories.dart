import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';


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

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }


  Future<void> _loadSongs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/music.json';
      File file = File(filePath);

      if (await file.exists()) {

        String jsonData = await file.readAsString();
        final List<dynamic> data = json.decode(jsonData);
        setState(() {
          _songs = data.map((json) => Song.fromJson(json)).toList();
          _filteredSongs = _songs;
          isLoading = false;
        });
      } else {


        final String response = await rootBundle.loadString('assets/songs/music.json');
        final List<dynamic> data = json.decode(response);
        setState(() {
          _songs = data.map((json) => Song.fromJson(json)).toList();
          _filteredSongs = _songs;
          isLoading = false;
        });


        await _saveSongsToLocalStorage();
      }
    } catch (e) {
      print('Error loading songs: $e');
    }
  }



  Future<void> _saveSongsToLocalStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/music.json';
      File file = File(filePath);
      String jsonData = json.encode(_songs.map((song) => song.toJson()).toList());
      await file.writeAsString(jsonData);
      print('Songs saved to local storage.');
    } catch (e) {
      print('Error saving songs: $e');
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
        return AlertDialog(
          title: Text('Add New Song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Song title input
              TextField(
                decoration: InputDecoration(labelText: 'Song Title'),
                onChanged: (value) {
                  songTitle = value;
                },
              ),
              SizedBox(height: 10),

              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );

                  if (result != null) {
                    imageFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image selected!')));
                  }
                },
                child: Text('Pick Image'),
              ),
              SizedBox(height: 10),
              // Pick audio file button
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp3', 'wav'],
                  );

                  if (result != null) {
                    audioFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio selected!')));
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
              onPressed: () async {
                if (songTitle != null && imageFile != null && audioFile != null) {
                  final newSong = Song(
                    title: songTitle!,
                    emotion: ['unknown'],
                    keywords: ['user', 'added'],
                    link: audioFile!.path,
                    image: imageFile!.path,
                    isFromAssets: false,
                  );

                  setState(() {
                    _songs.add(newSong);
                    _filteredSongs = List.from(_songs);
                  });

                  await _saveSongsToLocalStorage();

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Song added successfully!')));
                  Navigator.of(context).pop(); // Close dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a title, image, and audio file.')));
                }
              },
            ),
          ],
        );
      },
    );
  }




  // Delete song
  void _deleteSong(int index) async {
    try {
      setState(() {
        _songs.removeAt(index);
        _filteredSongs = _songs;
      });
      await _saveSongsToLocalStorage();
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
            thickness: 8.0,
            radius: Radius.circular(20),
            thumbVisibility: true,
            child: ListView.builder(
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


// Song model class

class MusicTile extends StatefulWidget {
final int index;
final Song song;
final Function(int, AudioPlayer) onPlayPause;
final bool isPlaying;
final Function(int) onDelete;

MusicTile({
  required this.index,
  required this.song,
  required this.onPlayPause,
  required this.isPlaying,
  required this.onDelete,
});

@override
_MusicTileState createState() => _MusicTileState();
}

class _MusicTileState extends State<MusicTile> {
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Toggle play or pause
  void _togglePlayPause() async {
    if (!mounted) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (!widget.isPlaying) {
        if (widget.song.isFromAssets) {
          await _audioPlayer.play(AssetSource(widget.song.link));
        } else {
          await _audioPlayer.play(DeviceFileSource(widget.song.link));
        }
      } else {
        await _audioPlayer.resume();
      }
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    }
    widget.onPlayPause(widget.index, _audioPlayer);
  }

  // Rewind and fast forward
  void _rewind() {
    final newPosition = _position - Duration(seconds: 5);
    _audioPlayer.seek(newPosition);
  }

  void _fastForward() {
    final newPosition = _position + Duration(seconds: 5);
    _audioPlayer.seek(newPosition);
  }

  // Seek progress bar accurately based on tap
  void _onTapProgressBar(double tapPositionX, double totalWidth) {
    final double progress = tapPositionX / totalWidth;
    final newPosition = Duration(milliseconds: (progress * _duration.inMilliseconds).toInt());
    _audioPlayer.seek(newPosition);
  }

  // Show confirmation dialog before deleting
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this song?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                widget.onDelete(widget.index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      padding: EdgeInsets.all(20), // Increased padding
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: widget.song.isFromAssets
                    ? AssetImage(widget.song.image)
                    : FileImage(File(widget.song.image)) as ImageProvider,
              ),
            ),
          ),
          SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (details) {

                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final totalWidth = box.size.width;
                      _onTapProgressBar(details.localPosition.dx, totalWidth);
                    },
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 25),

          IconButton(
            icon: Icon(Icons.replay_5),
            iconSize: 35,
            color: Colors.blue,
            onPressed: _rewind,
          ),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            iconSize: 55,
            color: Colors.blue,
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: Icon(Icons.forward_5),
            iconSize: 35,
            color: Colors.blue,
            onPressed: _fastForward,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            iconSize: 35,
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
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
    this.isFromAssets = true,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'],
      emotion: List<String>.from(json['emotion']),
      keywords: List<String>.from(json['keywords']),
      link: json['link'],
      image: json['image'],
      isFromAssets: json['isFromAssets'] ?? true,
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
