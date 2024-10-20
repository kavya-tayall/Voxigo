import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';



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
    return _loadImage(imagePath);
  }


  Widget _loadImage(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String? url) {
          return Center(child: CircularProgressIndicator());
        },
        errorWidget: (BuildContext context, String? url, dynamic error) {
          print("Failed to load image from URL: $imagePath");
          return Icon(Icons.broken_image);
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load image from file: $imagePath");
          return Icon(Icons.broken_image);
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
              child: _loadImageFromAsset(imagePath),
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

  Widget _loadImageFromAsset(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print("Failed to load image from file: $imagePath");
        return Icon(Icons.broken_image);
      },
    );
  }
}