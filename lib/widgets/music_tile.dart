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
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioPath = '${directory.path}/music_files/${widget.song.link}';

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
          if (await File(audioPath).exists()) {
            await _audioPlayer.play(DeviceFileSource(audioPath));
          } else {
            throw Exception('Audio file not found: $audioPath');
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
    } catch (e) {
      print('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  void _rewind() {
    final newPosition = _position - Duration(seconds: 5);
    _audioPlayer
        .seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void _fastForward() {
    final newPosition = _position + Duration(seconds: 5);
    _audioPlayer.seek(newPosition < _duration ? newPosition : _duration);
  }

  void _onTapProgressBar(double tapPositionX, double totalWidth) {
    final double progress = tapPositionX / totalWidth;
    final newPosition =
    Duration(milliseconds: (progress * _duration.inMilliseconds).toInt());
    _audioPlayer.seek(newPosition);
  }

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
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });
  }

  Future<String> _setImagePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String imageName = widget.song.image;
      return '${directory.path}/music_files/$imageName';
    } catch (e) {
      print('Error fetching image path: $e');
      return '';
    }
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

    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      margin:
      EdgeInsets.symmetric(vertical: 15, horizontal: isTablet ? 40 : 20),
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
          FutureBuilder<String>(
            future: _imagePathFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(Icons.error, size: 40, color: Colors.red),
                );
              } else if (snapshot.hasData &&
                  snapshot.data!.isNotEmpty &&
                  File(snapshot.data!).existsSync()) {
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
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (details) {
                      final RenderBox box =
                      context.findRenderObject() as RenderBox;
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
            iconSize: isTablet ? 40 : 35,
            color: Colors.blue,
            onPressed: _rewind,
          ),
          IconButton(
            icon: Icon(_isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled),
            iconSize: isTablet ? 60 : 55,
            color: Colors.blue,
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: Icon(Icons.forward_5),
            iconSize: isTablet ? 40 : 35,
            color: Colors.blue,
            onPressed: _fastForward,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            iconSize: isTablet ? 40 : 35,
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
    );
  }
}