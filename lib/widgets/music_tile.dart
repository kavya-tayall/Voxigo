import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test_app/auth_logic.dart';
import 'package:path_provider/path_provider.dart';

import '../child_pages/music_page.dart';

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
  Future<String>? _imagePathFuture;


  void _togglePlayPause() async {
    final directory = await getApplicationDocumentsDirectory();

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
        print("playing right now");
        print('${directory.path}/music_files/${widget.song.link}');
        await _audioPlayer.play(DeviceFileSource('${directory.path}/music_files/${widget.song.link}'));
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
    _imagePathFuture = _setImagePath();


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

  Future<String> _setImagePath() async {
    final directory = await getApplicationDocumentsDirectory();
    // Assuming widget.song.image contains the unique image name
    String imageName = widget.song.image; // Unique image name
    String imagePath = '${directory.path}/music_files/$imageName';
    print('Image path: $imagePath'); // Debugging line
    return imagePath; // Return the full path
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

    return Container(
      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      padding: EdgeInsets.all(20),
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
          // Use FutureBuilder to wait until _imagePath is set
          FutureBuilder<String>(
            future: _imagePathFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a loading indicator while waiting for the image path
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                // Show an error icon if something went wrong
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(Icons.error, size: 40, color: Colors.red),
                );
              } else if (snapshot.hasData && File(snapshot.data!).existsSync()) {
                // Render the image once the path is ready
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(snapshot.data!)),
                    ),
                  ),
                );
              } else {
                // Show a placeholder if the file doesn't exist
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                );
              }
            },
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