import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
// ignore: depend_on_referenced_packages
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test_app/security.dart';
import 'package:test_app/fileUploadandDownLoad.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

Future<void> updateBoardInFirebase(
    String childId, List<Map<String, dynamic>> gridData) async {
  try {
    String path = 'user_folders/$childId/board.json';
    Reference storageRef = FirebaseStorage.instance.ref().child(path);

    Map<String, dynamic> boardData = {
      "buttons": gridData,
    };

    await storageRef.putString(jsonEncode(boardData),
        metadata: SettableMetadata(contentType: 'application/json'));
  } catch (e) {
    print("Error updating board in Firebase: $e");
  }
}

// Function to save an image locally
Future<void> saveImageLocally(File imageFile, String childId) async {
  try {
    final Directory appDir = await getApplicationDocumentsDirectory();

    // Create a directory path that includes ChildId before 'board_images'
    final String childDir = path.join(appDir.path, childId, 'board_images');

    // Ensure directory exists
    final Directory directory = Directory(childDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('Created directory: $childDir');
    }

    // Save file locally
    String fileName = path.basename(imageFile.path); // Extract file name
    final String localPath = path.join(childDir, fileName);
    await File(localPath).writeAsBytes(await imageFile.readAsBytes());
    print('Image saved locally at: $localPath');
  } catch (e) {
    print("Error saving image locally: $e");
  }
}

Future<String> uploadFileToFirebase(List<int> fileBytes, String fileName,
    String childId, String firebasePath, bool forChild) async {
  try {
    // Save file temporarily to disk
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/$fileName';
    final file = File(tempFilePath);
    await file.writeAsBytes(fileBytes);

    // Get the download URL
    String firebaseImageUrl = await uploadEncryptedFileToFirebase(
        fileBytes, fileName, childId, firebasePath, forChild);
    return firebaseImageUrl;
  } catch (e) {
    throw Exception("Error uploading file to Firebase: $e");
  } finally {
    // Clean up the temporary file
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (cleanupError) {
      print("Error cleaning up temporary file: $cleanupError");
    }
  }
}

Future<String> uploadEncryptedFileToFirebase(List<int> fileBytes,
    String fileName, String childId, String firebasepath, bool forChild) async {
  try {
    Reference firebaseStorageRef = FirebaseStorage.instance.ref(firebasepath);

    // Convert List<int> to Uint8List for encryption
    Uint8List fileContent = Uint8List.fromList(fileBytes);

    // Encrypt the file content
    Map<String, dynamic> encryptionResult =
        await encryptFileContent(fileContent, forChild, childId);
    Uint8List encryptedContent = encryptionResult['encryptedContent'];
    Uint8List iv = encryptionResult['iv'];

// Automatically determine content type from file name
    String? contentType = lookupMimeType(fileName);

    // Ensure content type is not null (fallback to binary if unknown)
    contentType = 'application/octet-stream';

    // Upload encrypted file to Firebase Storage with IV as metadata
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'iv': base64Encode(iv)},
    );

    await firebaseStorageRef.putData(encryptedContent, metadata);
    String firebaseImageUrl = await firebaseStorageRef.getDownloadURL();
    print("File encrypted and uploaded successfully");
    return firebaseImageUrl;
  } catch (e) {
    throw Exception("Error uploading file to Firebase: $e");
  }
}

Future<void> uploadMP3OrCoverImageFile(File file, String path, String childId,
    String fileName, bool forChild) async {
  try {
    // Read file bytes
    List<int> fileBytes = await file.readAsBytes();

    // Call the reusable uploadFileToFirebase method
    String firebaseFileUrl = await uploadFileToFirebase(
        fileBytes, fileName, childId, path, forChild);

    print("File uploaded successfully to $path. URL: $firebaseFileUrl");
  } catch (e) {
    print("Error uploading file to Firebase: $e");
  }
}

Future<void> parentUploadMp3orCoverImageFileToFirebase(
    PlatformFile file, String path, String childId, bool forChild) async {
  try {
    print("Debug: Attempting to upload file '${file.name}' to path: $path");

    if (file.bytes != null) {
      // Upload file using bytes
      print("Debug: Uploading file '${file.name}' from memory.");
      await uploadFileToFirebase(
          file.bytes!, file.name, childId, path, forChild);
    } else if (file.path != null) {
      // Upload file from local path
      final fileToUpload = File(file.path!);
      if (await fileToUpload.exists()) {
        print(
            "Debug: Uploading file '${file.name}' from local path: ${file.path}");
        List<int> fileBytes = await fileToUpload.readAsBytes();
        await uploadFileToFirebase(
            fileBytes, file.name, childId, path, forChild);
      } else {
        print("Error: File does not exist at path: ${file.path}");
        return;
      }
    } else {
      print("Error: No valid source found for file '${file.name}'");
      return;
    }

    print("Success: File '${file.name}' uploaded successfully to path: $path");
  } on FirebaseException catch (e) {
    print("Firebase Error: ${e.message}");
    print("Error Code: ${e.code}");
  } catch (e, stackTrace) {
    print("General Error: $e");
    print("Stack Trace: $stackTrace");
  }
}
//////////////////////// Downloading Files ////////////////////////

Future<String> downloadFileFromFirebaseOld(String fileName, String childId,
    File localFile, String firebasepath) async {
  try {
    // Construct the storage path
    final Reference storageRef =
        FirebaseStorage.instance.ref().child(firebasepath);

    // Get the download URL
    final String downloadUrl = await storageRef.getDownloadURL();

    // Download the image data
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode == 200) {
      // Save the downloaded image locally
      await localFile.writeAsBytes(response.bodyBytes);
      print('File downloaded and saved locally at: ${localFile.path}');
      return localFile.path;
    } else {
      throw Exception('Failed to download file from Firebase Storage');
    }
  } catch (e) {
    print("Error downloading file from Firebase: $e");
    throw Exception("Failed to download file from Firebase");
  }
}

Future<String> downloadFileFromFirebase(String fileName, String childId,
    File localFile, String firebasepath, bool forChild) async {
  try {
    // Use the shared `downloadAndDecryptFile` method for downloading
    await downloadAndDecryptFile(
        firebasepath, localFile.path, forChild, childId);
    print(
        'File downloaded and saved locally (decrypted if necessary) at: ${localFile.path}');
    return localFile.path;
  } catch (e) {
    print("Error downloading file from Firebase: $e");
    throw Exception("Failed to download file from Firebase");
  }
}

/// Downloads and optionally decrypts a file from Firebase Storage.
Future<void> downloadAndDecryptFile(
    String storagePath, String localPath, bool forChild, String childId) async {
  try {
    // Reference to the file in Firebase Storage
    final ref = FirebaseStorage.instance.ref(storagePath);

    // Download the content
    final encryptedContent = await ref.getData();

    // Retrieve the IV from metadata
    final metadata = await ref.getMetadata();
    final ivBase64 = metadata.customMetadata?['iv'];

    // Check if the file is encrypted (IV is present) or not
    if (ivBase64 == null) {
      print("File is not encrypted, saving directly.");
      File localFile = File(localPath);
      await localFile.writeAsBytes(encryptedContent!);
      print("File downloaded successfully without decryption.");
    } else {
      print("File is encrypted, decrypting...");
      Uint8List iv = base64Decode(ivBase64);

      // Decrypt the content
      Uint8List decryptedContent =
          await decryptFileContent(encryptedContent!, iv, forChild, childId);

      // Save the decrypted content to a local file
      File localFile = File(localPath);
      await localFile.writeAsBytes(decryptedContent);
      print("File downloaded and decrypted successfully.");
    }
  } catch (e) {
    print("Error during file download or decryption: $e");
    throw Exception("Failed to download or decrypt file");
  }
}

Future<String> fetchBoardImageFromStorage(
    String imageName, String childId, bool forChild) async {
  try {
    // Get the application documents directory
    final Directory appDir = await getApplicationDocumentsDirectory();

    // Define the local directory structure
    final String childDir = path.join(appDir.path, childId, 'board_images');
    final Directory directory = Directory(childDir);

    // Ensure the directory exists
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('Created directory: $childDir');
    }

    // Define the local image file path
    final File localImage = File(path.join(childDir, imageName));

    // Check if the image already exists locally
    if (await localImage.exists()) {
      print('Image found locally: ${localImage.path}');
      return localImage.path;
    } else {
      // Download image from Firebase
      String firebasepath = 'user_folders/$childId/board_images/$imageName';

      final String downloadedPath = await downloadFileFromFirebase(
          imageName, childId, localImage, firebasepath, forChild);
      return downloadedPath;
    }
  } catch (e) {
    print("Error fetching image: $e");
    return '';
  }
}

/// Downloads a cover image from Firebase Storage and saves it locally.
Future<File?> downloadCoverImage(
    String fileName, String childId, bool forChild) async {
  try {
    print(
        'Attempting to download cover image: $fileName for childId: $childId');

    // Construct the Firebase Storage path
    String firebasePath =
        'user_folders/$childId/music_info/cover_images/$fileName';

    // Get the base application directory
    final directory = await getApplicationDocumentsDirectory();

    // Build the desired path structure
    final coverImagesDirectory = Directory(
      path.join(directory.path, childId, 'music_info', 'cover_images'),
    );

    // Ensure the directory exists
    if (!await coverImagesDirectory.exists()) {
      await coverImagesDirectory.create(recursive: true);
    }

    // Define the full file path
    final filePath = path.join(coverImagesDirectory.path, fileName);
    final file = File(filePath);

    // Check if the file already exists locally
    if (await file.exists()) {
      print('Cover image already exists at: $filePath');
      return file;
    }

    // Use the existing method to download and save the file
    final savedFilePath = await downloadFileFromFirebase(
        fileName, childId, file, firebasePath, forChild);

    if (savedFilePath.isNotEmpty) {
      print('Cover image downloaded successfully to: $savedFilePath');
      return file;
    } else {
      print('Failed to download and save the cover image.');
      return null;
    }
  } catch (e) {
    print('Error downloading cover image: $e');
    return null;
  }
}

/// Downloads a board image from Firebase Storage and saves it locally.
Future<File?> downloadBoardImage(
    String fileName, String childId, bool forChild) async {
  try {
    print('Attempting to download board image: $fileName');

    // Construct the Firebase Storage path
    String firebasePath = 'user_folders/$childId/board_images/$fileName';

    // Get the base application directory
    final directory = await getApplicationDocumentsDirectory();

    // Build the desired path structure
    final boardImagesDirectory = Directory(
      path.join(directory.path, childId, 'board_images'),
    );

    // Ensure the directory exists
    if (!await boardImagesDirectory.exists()) {
      await boardImagesDirectory.create(recursive: true);
      print('Created directory: ${boardImagesDirectory.path}');
    }

    // Define the full file path
    final filePath = path.join(boardImagesDirectory.path, fileName);
    final file = File(filePath);

    // Check if the file already exists locally
    if (await file.exists()) {
      print('File already exists at: $filePath');
      return file;
    }

    // Use the existing method to download and save the file
    final savedFilePath = await downloadFileFromFirebase(
        fileName, childId, file, firebasePath, forChild);

    if (savedFilePath.isNotEmpty) {
      print('Board image downloaded successfully to: $savedFilePath');
      return file;
    } else {
      print('Failed to download and save the board image.');
      return null;
    }
  } catch (e) {
    print('Error downloading board image: $e');
    return null;
  }
}

/// Downloads an MP3 file from Firebase Storage and saves it locally.
Future<File?> downloadMp3(
    String fileName, String childId, bool forChild) async {
  try {
    print('Attempting to download MP3: $fileName for childId: $childId');

    // Construct the Firebase Storage path
    String firebasePath =
        'user_folders/$childId/music_info/mp3 files/$fileName';

    // Get the base application directory
    final directory = await getApplicationDocumentsDirectory();

    // Build the desired path structure
    final mp3FilesDirectory = Directory(
      path.join(directory.path, childId, 'music_info', 'mp3 files'),
    );

    // Ensure the directory exists
    if (!await mp3FilesDirectory.exists()) {
      await mp3FilesDirectory.create(recursive: true);
    }

    // Define the full file path
    final filePath = path.join(mp3FilesDirectory.path, fileName);
    final file = File(filePath);

    // Check if the file already exists locally
    if (await file.exists()) {
      print('File already exists at: $filePath');
      return file;
    }

    // Use the existing method to download and save the file
    final savedFilePath = await downloadFileFromFirebase(
        fileName, childId, file, firebasePath, forChild);

    if (savedFilePath.isNotEmpty) {
      print('MP3 file downloaded successfully to: $savedFilePath');
      return file;
    } else {
      print('Failed to download and save the MP3 file.');
      return null;
    }
  } catch (e) {
    print('Error downloading MP3: $e');
    return null;
  }
}

/// Fetches an MP3 cover image from Firebase Storage and saves it locally if not already available.
Future<String> fetchMP3CoverImageFromStorage(
    String imageName, String childId, bool forChild) async {
  try {
    // Get the base application directory
    final appDocDir = await getApplicationDocumentsDirectory();

    // Define the local image path including `childId` in the folder structure
    final localImagePath = path.join(
      appDocDir.path,
      childId,
      'music_info',
      'cover_images',
      imageName,
    );

    final localFile = File(localImagePath);

    print("Local Image Path: $localImagePath");

    // Check if the file exists locally
    if (await localFile.exists()) {
      print("Loading image from local storage: $localImagePath");
      return localFile.path;
    }

    print("Image not found locally, downloading from Firebase...");

    // Define the storage path in Firebase
    final firebasePath =
        'user_folders/$childId/music_info/cover_images/$imageName';

    // Use the existing method to download the file
    await downloadFileFromFirebase(
        imageName, childId, localFile, firebasePath, forChild);

    if (await localFile.exists()) {
      print("Image saved locally: $localImagePath");
      return localFile.path;
    } else {
      print("Failed to download and save the image.");
      return '';
    }
  } catch (e) {
    print("Error loading image for $imageName: $e");
    return '';
  }
}

/// Fetches an audio file from Firebase Storage and saves it locally if not already available.
Future<String> fetchAudioFromStorage(
    String audioName, String childId, bool forChild) async {
  try {
    // Get the base application directory
    final appDocDir = await getApplicationDocumentsDirectory();

    // Define the local audio path including `childId` in the folder structure
    final localAudioPath = path.join(
      appDocDir.path,
      childId,
      'music_info',
      'mp3 files',
      audioName,
    );

    final localFile = File(localAudioPath);
    print("Local Audio Path: $localFile");

    // Check if the file exists locally
    if (await localFile.exists()) {
      print("Loading audio from local storage: $localAudioPath");
      return localFile.path;
    }

    print("Audio not found locally, downloading from Firebase...");

    // Define the storage path in Firebase
    final firebasePath =
        'user_folders/$childId/music_info/mp3 files/$audioName';

    // Use the existing method to download the file
    await downloadFileFromFirebase(
        audioName, childId, localFile, firebasePath, forChild);

    if (await localFile.exists()) {
      print("Audio saved locally: $localAudioPath");
      return localAudioPath;
    } else {
      print("Failed to download and save the audio.");
      return '';
    }
  } catch (e) {
    print("Error loading audio for $audioName: $e");
    return '';
  }
}
