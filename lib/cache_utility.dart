import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:test_app/widgets/child_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;




Future<File> downloadMp3(String fileName) async {
  print('Attempting to download MP3: $fileName');
  final storageRef = FirebaseStorage.instance.ref('music_info/mp3 files/$fileName');

  // Log the full path
  print('Accessing file at: ${storageRef.fullPath}');

  final directory = await getApplicationDocumentsDirectory();
  final musicDirectory = Directory('${directory.path}/music_files/');

  if (!await musicDirectory.exists()) {
    await musicDirectory.create(recursive: true);
  }

  final filePath = '${musicDirectory.path}$fileName';
  final file = File(filePath);

  if (!await file.exists()) {
    try {
      final downloadUrl = await storageRef.getDownloadURL();
      print('Download URL: $downloadUrl');

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded to: $filePath');
      } else {
        print('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  } else {
    print('File already exists at: $filePath');
  }

  return file;
}

Future<File> downloadCoverImage(String fileName) async {
  final storageRef = FirebaseStorage.instance.ref('music_info/cover_images/$fileName');
  final directory = await getApplicationDocumentsDirectory();
  final musicDirectory = Directory('${directory.path}/music_files/');

  if (!await musicDirectory.exists()) {
    await musicDirectory.create(recursive: true);
  }
  print(musicDirectory.path);

  final filePath = '${musicDirectory.path}$fileName';
  final file = File(filePath);

  if (!await file.exists()) {
    final downloadUrl = await storageRef.getDownloadURL();
    final response = await http.get(Uri.parse(downloadUrl));
    await file.writeAsBytes(response.bodyBytes);
  }

  return file;
}

Future<File> downloadBoardImage(String fileName) async {
  print(fileName);
  final storageRef = FirebaseStorage.instance.ref('initial_board_images/$fileName');
  final directory = await getApplicationDocumentsDirectory();
  final boardDirectory = Directory('${directory.path}\\board_images\\');

  if (!await boardDirectory.exists()) {
    await boardDirectory.create(recursive: true);
  }

  final filePath = '${boardDirectory.path}$fileName';
  final file = File(filePath);

  if (!await file.exists()) {
    final downloadUrl = await storageRef.getDownloadURL();
    print(downloadUrl);
    final response = await http.get(Uri.parse(downloadUrl));
    await file.writeAsBytes(response.bodyBytes);
    print(filePath);
  }

  return file;
}

Future<void> downloadFromList(List listData) async{
  for (var i=0; i<listData.length; i++){
    await downloadBoardImage(listData[i]["image_url"]);
    if (listData[i]["folder"] == true) {
      await downloadFromList(listData[i]["buttons"]);
    }
  }
}

/*
Future<void>? checkIfChanges(BuildContext context, String childUsername) async {
  final childProvider = Provider.of<ChildProvider>(context, listen: false);

  String? musicJsonString = await childProvider.fetchJson('music.json');
  String? boardJsonString = await childProvider.fetchJson('board.json');

  final List<dynamic> data = json.decode(musicJsonString!);
}
*/

