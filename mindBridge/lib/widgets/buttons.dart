import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FirstButton extends StatefulWidget {
  final String id;
  final String imagePath;
  final String text;
  final double size; // Size is passed for compatibility
  final VoidCallback onPressed;

  const FirstButton({
    Key? key,
    required this.id,
    required this.imagePath,
    required this.text,
    required this.size,
    required this.onPressed,
  }) : super(key: key);

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "image_url": imagePath,
      "label": text,
      "folder": false,
    };
  }

  @override
  State<FirstButton> createState() => _FirstButtonState();
}

class _FirstButtonState extends State<FirstButton> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // Maintain square shape
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: _loadImageWithLoadingIndicator(widget.imagePath),
            ),
            const SizedBox(height: 4), // Space between image and text
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadImageWithLoadingIndicator(String imagePath) {
    return _loadImage(imagePath);
  }

  Widget _loadImage(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) {
          print("Failed to load image from URL: $imagePath");
          return const Icon(Icons.broken_image);
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from file: $imagePath");
          return const Icon(Icons.broken_image);
        },
      );
    }
  }
}

class FolderButton extends StatelessWidget {
  final String imagePath;
  final String text;
  final int ind;
  final double size; // Size is passed for compatibility
  final VoidCallback onPressed;

  const FolderButton({
    Key? key,
    required this.imagePath,
    required this.text,
    required this.ind,
    required this.size,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // Maintain square shape
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: _loadImageFromAsset(imagePath),
            ),
            const SizedBox(height: 4), // Space between image and text
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadImageFromAsset(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print("Failed to load image from file: $imagePath");
        return const Icon(Icons.broken_image);
      },
    );
  }
}
