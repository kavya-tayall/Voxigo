import 'dart:io';

import 'package:flutter/material.dart';

import '../child_pages/home_page.dart';

class FirstButton extends StatefulWidget {
  final String id;
  final String imagePath;
  final String text;
  final double size;
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _loadImageWithLoadingIndicator(widget.imagePath),
            ),
            Text(
              widget.text,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to load images from assets, URLs, or local file system with a loading indicator
  Widget _loadImageWithLoadingIndicator(String imagePath) {
    return _loadImage(imagePath); // Directly load image with proper loading state handling
  }

  // Helper method to load images from assets, URLs, or local file system
  Widget _loadImage(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      // Load from network
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator()); // Show progress while loading
        },
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from URL: $imagePath");
          return Icon(Icons.broken_image); // Fallback for broken image URLs
        },
      );
    } else if (imagePath.startsWith('file://')) {
      String cleanedPath = imagePath.replaceFirst('file://', '');
      if (File(cleanedPath).existsSync()) {
        // Load from local file system
        return Image.file(
          File(cleanedPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Failed to load image from file: $cleanedPath");
            return Icon(Icons.broken_image); // Fallback for broken image files
          },
        );
      } else {
        print("File does not exist: $cleanedPath");
        return Icon(Icons.broken_image); // Fallback if file does not exist
      }
    } else {
      // Load from assets
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from assets: $imagePath");
          return Icon(Icons.broken_image); // Fallback for broken assets
        },
      );
    }
  }
}

class FolderButton extends StatelessWidget {
  final String imagePath;
  final String text;
  final int ind;
  final double size;
  final VoidCallback onPressed;

  FolderButton({
    Key? key,
    required this.imagePath,
    required this.text,
    required this.ind,
    required this.size,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _loadImageFromAsset(imagePath), // Image always from asset
            ),
            Text(
              text,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to load images from assets
  Widget _loadImageFromAsset(String imagePath) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print("Failed to load image from assets: $imagePath");
        return Icon(Icons.broken_image); // Fallback for broken assets
      },
    );
  }
}
