import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Downloads an MP3 file from Firebase Storage and saves it locally.
Future<File?> downloadMp3(String fileName) async {
  try {
    print('Attempting to download MP3: $fileName');
    final storageRef =
    FirebaseStorage.instance.ref('music_info/mp3 files/$fileName');

    print('Accessing file at: ${storageRef.fullPath}');

    final directory = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}music_files${Platform.pathSeparator}');

    if (!await musicDirectory.exists()) {
      await musicDirectory.create(recursive: true);
    }

    final filePath = '${musicDirectory.path}$fileName';
    final file = File(filePath);

    if (!await file.exists()) {
      final downloadUrl = await storageRef.getDownloadURL();
      print('Download URL: $downloadUrl');

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded to: $filePath');
      } else {
        print('Failed to download file: ${response.statusCode}');
        return null;
      }
    } else {
      print('File already exists at: $filePath');
    }

    return file;
  } catch (e) {
    print('Error downloading MP3: $e');
    return null;
  }
}

/// Downloads a cover image from Firebase Storage and saves it locally.
Future<File?> downloadCoverImage(String fileName) async {
  try {
    final storageRef =
    FirebaseStorage.instance.ref('music_info/cover_images/$fileName');
    final directory = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}music_files${Platform.pathSeparator}');

    if (!await musicDirectory.exists()) {
      await musicDirectory.create(recursive: true);
    }

    final filePath = '${musicDirectory.path}$fileName';
    final file = File(filePath);

    if (!await file.exists()) {
      final downloadUrl = await storageRef.getDownloadURL();
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      } else {
        print('Failed to download cover image: ${response.statusCode}');
        return null;
      }
    }

    return file;
  } catch (e) {
    print('Error downloading cover image: $e');
    return null;
  }
}

/// Downloads a board image from Firebase Storage and saves it locally.
Future<File?> downloadBoardImage(String fileName) async {
  try {
    print('Attempting to download board image: $fileName');
    final storageRef =
    FirebaseStorage.instance.ref('initial_board_images/$fileName');
    final directory = await getApplicationDocumentsDirectory();
    final boardDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}board_images${Platform.pathSeparator}');

    if (!await boardDirectory.exists()) {
      await boardDirectory.create(recursive: true);
    }

    final filePath = '${boardDirectory.path}$fileName';
    final file = File(filePath);

    if (!await file.exists()) {
      final downloadUrl = await storageRef.getDownloadURL();
      print('Download URL: $downloadUrl');

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('Board image downloaded to: $filePath');
      } else {
        print('Failed to download board image: ${response.statusCode}');
        return null;
      }
    } else {
      print('File already exists at: $filePath');
    }

    return file;
  } catch (e) {
    print('Error downloading board image: $e');
    return null;
  }
}

/// Recursively downloads all board images and their nested items.
Future<void> downloadFromList(List listData) async {
  try {
    for (var i = 0; i < listData.length; i++) {
      if (listData[i].containsKey("image_url")) {
        await downloadBoardImage(listData[i]["image_url"]);
      }
      if (listData[i]["folder"] == true && listData[i].containsKey("buttons")) {
        await downloadFromList(listData[i]["buttons"]);
      }
    }
  } catch (e) {
    print('Error downloading from list: $e');
  }
}