import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase storage import
import 'package:path/path.dart' as path; // Import to help with file paths

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

  Widget _loadImageWithLoadingIndicator(String imagePath) {
    print(imagePath);
    return FutureBuilder<Widget>(
      future: _loadImage(imagePath), // Load image from file or Firebase
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.broken_image);
        }
        return snapshot.data!;
      },
    );
  }


  Future<Widget> _loadImage(String imagePath) async {
    // Strip out 'Documents/board_images/' part from the path
    String cleanedImagePath = _cleanImagePath(imagePath);

    // Try loading the image from the local file system
    if (File(cleanedImagePath).existsSync()) {
      return Image.file(
        File(cleanedImagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from file: $cleanedImagePath");
          return Icon(Icons.broken_image);
        },
      );
    } else {
      // If not found locally, fallback to Firebase Storage with only the file name
      String fileName = path.basename(cleanedImagePath); // Extract file name only
      return await _loadImageFromFirebase(fileName);
    }
  }

  String _cleanImagePath(String imagePath) {
    // Remove 'Documents/board_images/' or any similar unwanted parts from the imagePath
    if (imagePath.contains('Documents/board_images/')) {
      return imagePath.replaceAll('Documents/board_images/', '');
    } else if (imagePath.contains('Documents\\board_images\\')) {
      return imagePath.replaceAll('Documents\\board_images\\', '');
    }
    return imagePath; // Return the cleaned-up path
  }

  Future<Widget> _loadImageFromFirebase(String fileName) async {
    try {
      // Construct the reference to the image in Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('initial_board_images/$fileName');

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();

      // Return the image from the Firebase URL
      return Image.network(
        downloadUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from Firebase: $fileName");
          return Icon(Icons.broken_image);
        },
      );
    } catch (e) {
      print("Failed to fetch image from Firebase: $fileName, error: $e");
      return Icon(Icons.broken_image);
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
              child: _loadImageWithLoadingIndicator(imagePath),
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

  Widget _loadImageWithLoadingIndicator(String imagePath) {
    return FutureBuilder<Widget>(
      future: _loadImage(imagePath), // Load image from file or Firebase
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.broken_image);
        }
        return snapshot.data!;
      },
    );
  }

  Future<Widget> _loadImage(String imagePath) async {
    // Strip out 'Documents/board_images/' part from the path
    String cleanedImagePath = _cleanImagePath(imagePath);

    // Try loading the image from the local file system
    if (File(cleanedImagePath).existsSync()) {
      return Image.file(
        File(cleanedImagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from file: $cleanedImagePath");
          return Icon(Icons.broken_image);
        },
      );
    } else {
      // If not found locally, fallback to Firebase Storage with only the file name
      String fileName = path.basename(cleanedImagePath); // Extract file name only
      return await _loadImageFromFirebase(fileName);
    }
  }

  String _cleanImagePath(String imagePath) {
    // Remove 'Documents/board_images/' or any similar unwanted parts from the imagePath
    if (imagePath.contains('Documents/board_images/')) {
      return imagePath.replaceAll('Documents/board_images/', '');
    } else if (imagePath.contains('Documents\\board_images\\')) {
      return imagePath.replaceAll('Documents\\board_images\\', '');
    }
    return imagePath; // Return the cleaned-up path
  }

  Future<Widget> _loadImageFromFirebase(String fileName) async {
    try {
      // Construct the reference to the image in Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('initial_board_images/$fileName');

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();

      // Return the image from the Firebase URL
      return Image.network(
        downloadUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from Firebase: $fileName");
          return Icon(Icons.broken_image);
        },
      );
    } catch (e) {
      print("Failed to fetch image from Firebase: $fileName, error: $e");
      return Icon(Icons.broken_image);
    }
  }
}
