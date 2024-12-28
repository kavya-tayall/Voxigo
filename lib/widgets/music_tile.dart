import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:test_app/auth_logic.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:test_app/widgets/child_provider.dart';
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

  void _togglePlayPause(String childId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Include childId in the directory structure
      final audioPath = path.join(
          directory.path, childId, 'music_info/mp3 files', widget.song.link);

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
          content: Text(
              'Are you sure you want to delete this music file? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
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
    ChildProvider childProvider =
        Provider.of<ChildProvider>(context, listen: false);
    if (childProvider.childId != null) {
      _imagePathFuture = _setImagePath(childProvider.childId!);
    } else {
      _imagePathFuture = Future.value('');
    }

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

  Future<String> _setImagePath(String childId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String imageName = widget.song.image;

      // Add childId to the directory path
      return path.join(
          directory.path, childId, 'music_info/cover_images', imageName);
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

  Widget build(BuildContext context) {
    double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 500;

    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: isSmallScreen ? 8 : 20, // Adjust for smaller screens
      ),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 20),
      decoration: BoxDecoration(
        color: theme.primaryColorLight,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          FutureBuilder<String>(
            future: _imagePathFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingImagePlaceholder();
              } else if (snapshot.hasError) {
                return _buildErrorImagePlaceholder();
              } else if (snapshot.hasData &&
                  snapshot.data!.isNotEmpty &&
                  File(snapshot.data!).existsSync()) {
                return _buildImage(File(snapshot.data!));
              } else {
                return _buildDefaultImagePlaceholder();
              }
            },
          ),
          SizedBox(width: isSmallScreen ? 8 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: isSmallScreen ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 8),
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
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
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
          SizedBox(width: isSmallScreen ? 8 : 20),
          _buildIcon(theme, Icons.replay_5, _rewind, isSmallScreen),
          _buildIcon(
            theme,
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            () => _togglePlayPause(
                Provider.of<ChildProvider>(context, listen: false).childId!),
            isSmallScreen,
            isPrimary: true,
          ),
          _buildIcon(theme, Icons.forward_5, _fastForward, isSmallScreen),
          _buildIcon(
              theme, Icons.delete, _showDeleteConfirmationDialog, isSmallScreen,
              isDelete: true),
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, IconData icon, VoidCallback onPressed,
      bool isSmallScreen,
      {bool isPrimary = false, bool isDelete = false}) {
    return IconButton(
      icon: Icon(icon, color: isDelete ? Colors.red : theme.primaryColor),
      iconSize: isSmallScreen
          ? (isPrimary ? 35 : 25)
          : (isPrimary ? 40 : 30), // Smaller size for smaller screens
      onPressed: onPressed,
    );
  }

  Widget _buildLoadingImagePlaceholder() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorImagePlaceholder() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Icon(Icons.error, size: 30, color: Colors.red),
    );
  }

  Widget _buildImage(File imageFile) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: FileImage(imageFile),
        ),
      ),
    );
  }

  Widget _buildDefaultImagePlaceholder() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Icon(Icons.image, size: 30, color: Colors.grey[600]),
    );
  }
}
