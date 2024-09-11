import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class MusicPage extends StatefulWidget {
  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  AudioPlayer? _currentlyPlayingPlayer; // Store the current audio player
  int? _currentlyPlayingIndex;
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final String response = await rootBundle.loadString('assets/songs/music.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _songs = data.map((json) => Song.fromJson(json)).toList();
      _filteredSongs = _songs; // Initially show all songs
    });
  }

  void _onPlayPause(int index, AudioPlayer audioPlayer) async {
    // If a different song is playing, stop it
    if (_currentlyPlayingIndex != null && _currentlyPlayingIndex != index) {
      _currentlyPlayingPlayer?.stop();
    }

    // Update the currently playing player and index
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body: Column(
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _filteredSongs.length,
              itemBuilder: (context, index) {
                return MusicTile(
                  index: index,
                  song: _filteredSongs[index],
                  onPlayPause: _onPlayPause,
                  isPlaying: _currentlyPlayingIndex == index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MusicTile extends StatefulWidget {
  final int index;
  final Song song;
  final Function(int, AudioPlayer) onPlayPause;
  final bool isPlaying;

  MusicTile({required this.index, required this.song, required this.onPlayPause, required this.isPlaying});

  @override
  _MusicTileState createState() => _MusicTileState();
}

class _MusicTileState extends State<MusicTile> {
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();  // Pause instead of stop to resume later
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (!widget.isPlaying) {
        // Only play if this song is not already playing
        await _audioPlayer.play(AssetSource(widget.song.link));
      } else {
        await _audioPlayer.resume(); // Resume from the paused position
      }
      setState(() {
        _isPlaying = true;
      });
    }
    widget.onPlayPause(widget.index, _audioPlayer);
  }

  void _onTapProgressBar(Offset localPosition, Size progressBarSize) {
    final double tapPosition = localPosition.dx;
    final double progress = tapPosition / progressBarSize.width;
    final newPosition = Duration(milliseconds: (progress * _duration.inMilliseconds).toInt());
    _audioPlayer.seek(newPosition);
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
  Widget build(BuildContext context) {
    double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
//hi
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              widget.song.image, // Display song image
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.replay_10, color: Colors.blue[900]),
                      onPressed: () {
                        _audioPlayer.seek(_position - Duration(seconds: 10));
                      },
                    ),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.blue[900]),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon: Icon(Icons.forward_10, color: Colors.blue[900]),
                      onPressed: () {
                        _audioPlayer.seek(_position + Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return InkWell(
                      onTapUp: (TapUpDetails details) {
                        _onTapProgressBar(details.localPosition, constraints.biggest);
                      },
                      child: Container(
                        height: 5.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: progress * constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[900],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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

  Song({
    required this.title,
    required this.emotion,
    required this.keywords,
    required this.link,
    required this.image,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'],
      emotion: List<String>.from(json['emotion']),
      keywords: List<String>.from(json['keywords']),
      link: json['link'],
      image: json['image'], // Image field added
    );
  }
}
