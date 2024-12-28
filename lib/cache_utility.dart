import 'dart:io';
import 'dart:collection';
import 'dart:async';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:test_app/authExceptions.dart';
import 'package:test_app/security.dart';
import 'package:test_app/fileUploadandDownLoad.dart';
import 'widgets/child_provider.dart';
import 'package:test_app/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart' as path;

Future<String> fetchChildrenAnonDataforAI({
  required DateTime filterDate,
  bool byParent = true,
}) async {
  try {
    print('inside fetchChildrenAnonDataforAI');

    List<dynamic> childrenIDList = [];

    // Fetch parent data if forChild is true
    if (byParent) {
      DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (parentSnapshot.exists) {
        Map<String, dynamic>? parentData =
            parentSnapshot.data() as Map<String, dynamic>?;
        if (parentData != null && parentData['children'] != null) {
          childrenIDList = parentData['children'];
        } else {
          print("Parent document exists but children list is missing.");
          return "no data";
        }
      } else {
        print("Parent document not found.");
        return "no data";
      }
    } else {
      // If not forChild, use the current user's UID
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        childrenIDList.add(currentUserId);
      } else {
        print("No current user logged in.");
        return "no data";
      }
    }

    // Process data for each child
    Map<String, dynamic> childrenData = {};
    for (String childId in childrenIDList) {
      List<Map<String, dynamic>> selectedButtons = [];
      List<Map<String, dynamic>> selectedFeelings = [];

      // Fetch selected buttons data
      QuerySnapshot buttonsSnapshot = await FirebaseFirestore.instance
          .collection('selectedButtons')
          .where('childId', isEqualTo: childId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(filterDate))
          .get();

      for (var doc in buttonsSnapshot.docs) {
        selectedButtons.add(doc.data() as Map<String, dynamic>);
      }

      // Fetch selected feelings data
      QuerySnapshot feelingsSnapshot = await FirebaseFirestore.instance
          .collection('selectedFeelings')
          .where('childId', isEqualTo: childId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(filterDate))
          .get();

      for (var doc in feelingsSnapshot.docs) {
        selectedFeelings.add(doc.data() as Map<String, dynamic>);
      }

      // Decrypt the selected data for the child
      List<dynamic> decryptedButtons =
          await decryptSelectedDataForChild(childId, selectedButtons);
      List<dynamic> decryptedFeelings =
          await decryptSelectedDataForChild(childId, selectedFeelings);

      // Remove 'iv' from the decrypted data
      decryptedButtons.forEach((button) {
        button.remove('iv'); // Remove 'iv' field
        button['timestamp'] =
            button['timestamp'].toDate(); // Convert to DateTime
      });

      decryptedFeelings.forEach((feeling) {
        feeling.remove('iv'); // Remove 'iv' field
        feeling['timestamp'] =
            feeling['timestamp'].toDate(); // Convert to DateTime
      });

      // Convert the feelings and buttons data into a list of strings
      var stringFeelingList = decryptedFeelings.join(", ");
      var stringButtonList = decryptedButtons.join(", ");

      // Create the response with anonymous data
      childrenData[childId] = {
        "userReference": childId, // Only childId is included
        "feelingsData": stringFeelingList,
        "buttonsData": stringButtonList,
      };
    }

    // Return the data as a string
    return childrenData.isNotEmpty
        ? childrenData.toString()
        : "No data available";
  } catch (e) {
    print('Error fetching data: $e');
    return "error";
  }
}

/// Process all assets for login user , called from base page defined in main.dart
Future<void> fetchLoginChildData(BuildContext context, bool forChild) async {
  try {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    // Fetch and process board.json
    String? childUsername = childProvider.childData?['username'];
    String? childId = childProvider.childId;
    String? boardJsonString =
        await childProvider.fetchJson("board.json", childId!);
    final Map<String, dynamic> boardData = json.decode(boardJsonString!);

    print(
        'Inside fetchLoginChildData now Calling fetchButtonLogsAndDownloadImages for $childUsername');

    // 1 First Step to fetch all the images from the board.json and download them as per the last update in button log
    await fetchButtonLogsAndDownloadImages(
        childUsername!, childId!, boardData["buttons"]!, forChild);

    //2. Second step to fetch and process music.json
    //fetchMusicFiles(context); -- commenting this code for optimization
  } catch (e) {
    print('Error fetching or parsing JSON: $e');
  }
}

Future<void> fetchMusicFiles(
    BuildContext context, String childId, bool forChild) async {
  final childProvider = Provider.of<ChildProvider>(context, listen: false);
  final String username = childProvider.childData?['username'];

  print('Inside fetchMusicFiles');

  QuerySnapshot<Object?>? appInstallationsSnapshot =
      await getAppInstallationsForUser(username, mp3: true);

  if (appInstallationsSnapshot == null) {
    print(
        'No app installation record found for this user and installation ID for Mp3. First copy all asset.');
    await copyMusicToLocalHolderFromAsset(childId);

    String? musicJsonString =
        await childProvider.fetchJson("music.json", childId);
    if (musicJsonString != null) {
      final List<dynamic> musicData = json.decode(musicJsonString);

      await downloadMp3FilesConcurrently(
          musicData, childId, username, forChild);
      return;
    } else {
      print('Failed to fetch or decode music.json');
    }
    return;
  }
  Timestamp appInstallationTimestamp =
      appInstallationsSnapshot.docs.first['timestamp'];

  print('Only need to now processing mp3 logs for $username');

  await processMP3Logs(username, childId, appInstallationTimestamp, forChild);
}

Future<QuerySnapshot<Object?>?> getAppInstallationsForUser(
  String username, {
  bool boardimg = false, // Default value
  bool mp3 = false, // Default value
}) async {
  try {
    // Get the Firebase App Installation ID
    String installationId = await FirebaseInstallations.instance.getId();
    final FirebaseFirestore db = FirebaseFirestore.instance;

    print('Checking app installations for user: $username');

    // Fetch the app installation record for the user and installation ID
    final QuerySnapshot appInstallationsSnapshot = await db
        .collection('app_installations')
        .where('installationId', isEqualTo: installationId)
        .where('username', isEqualTo: username)
        .get();

    if (appInstallationsSnapshot == null ||
        appInstallationsSnapshot.docs.isEmpty) {
      print(
          'No app installation record found for this user and installation ID.');
      return null;
    } else {
      print('App installation record already exists.');

      // Check if the app installation record has the mp3_processed field
      if (mp3) {
        bool mp3Processed =
            appInstallationsSnapshot.docs.first['mp3_processed'];
        if (mp3Processed) {
          print('MP3 files already processed for this app installation.');
          return appInstallationsSnapshot;
        } else {
          print('MP3 files not processed for this app installation.');
          return null;
        }
      }

      return appInstallationsSnapshot;
    }
  } catch (e) {
    print('Error checking app installations: $e');
    return null;
  }
}

/// Fetches button logs from Firestore and downloads the images to the device.
/// Also updates the app installation record to reflect the last time the app was updated for images.
Future<void> fetchButtonLogsAndDownloadImages(
    String username, String childId, List listData, bool forChild) async {
  try {
    print('Fetching button logs and downloading images for $username');
    // If no app installation record is found, refresh the grid from the latest board
    QuerySnapshot<Object?>? appInstallationsSnapshot =
        await getAppInstallationsForUser(username);

    if (appInstallationsSnapshot == null) {
      print(
          'No app installation record found for this user and installation ID. Perform full Refresh the app to create a new record.');
      await copyAllAssetsToAppFolder(childId);

      String lastImageUrl = await downloadAllImagesFromJsonList(
          listData, forChild,
          childId: childId, username: username);
      await updateInstalltionAfterFullRefreshofImages(lastImageUrl, username);
      return;
    }

    if (appInstallationsSnapshot.docs.isEmpty) {
      print(
          'No app installation record found for this user and installation ID. Perfomr full Refresh the app to create a new record.');
      await copyAllAssetsToAppFolder(childId);

      String lastImageUrl = await downloadAllImagesFromJsonList(
          listData, forChild,
          childId: childId, username: username);
      await updateInstalltionAfterFullRefreshofImages(lastImageUrl, username);
      return;
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    String installationId = await FirebaseInstallations.instance.getId();

    // Fetch button logs to check if any time any image was added to the board either by full refresh or by adding an image
    final QuerySnapshot buttonLogsSnapshot = await db
        .collection('button_log')
        .where('installationId', isEqualTo: installationId)
        .where('username', isEqualTo: username)
        .get();

    if (buttonLogsSnapshot.docs.isEmpty) {
      print(
          'No button logs found for username and installation.Perform full refresh.');
      await copyAllAssetsToAppFolder(childId);

      String lastImageUrl = await downloadAllImagesFromJsonList(
          listData, forChild,
          childId: childId, username: username);
      await updateInstalltionAfterFullRefreshofImages(lastImageUrl, username);
      return;
    }

    print(
        'now check the last image downloaded and download the images after that');

    // Get the timestamp of the app installation
    Timestamp appInstallationTimestamp =
        appInstallationsSnapshot.docs.first['timestamp'];

    // Process button logs to download images after the app installation timestamp
    await processButtonLogs(
        username, childId, appInstallationTimestamp, forChild);
  } catch (e) {
    print('Error fetching button logs and downloading images: $e');
  }
}

Future<String> downloadAllImagesFromJsonList(
  List listData,
  bool forChild, {
  required String username,
  required String childId,
  int maxConcurrent = 5,
}) async {
  String? lastImageUrl;
  final Queue<Future Function()> taskQueue = Queue();
  final Completer<void> queueEmptyCompleter = Completer();
  int activeTasks = 0;

  Future<void> processQueue() async {
    while (taskQueue.isNotEmpty || activeTasks > 0) {
      if (activeTasks < maxConcurrent && taskQueue.isNotEmpty) {
        final task = taskQueue.removeFirst();
        activeTasks++;
        task().whenComplete(() {
          activeTasks--;
        }).catchError((e) {
          print('Error in task: $e');
        });
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    queueEmptyCompleter.complete();
  }

  try {
    // Add tasks to the queue
    for (var item in listData) {
      if (item.containsKey("image_url")) {
        final imageUrl = item["image_url"];
        taskQueue.add(() async {
          await downloadBoardImage(imageUrl, childId, forChild);
          lastImageUrl = imageUrl; // Update last image URL
        });
      }
      if (item["folder"] == true && item.containsKey("buttons")) {
        taskQueue.add(() async {
          await downloadAllImagesFromJsonList(
            item["buttons"],
            forChild,
            username: username,
            childId: childId,
            maxConcurrent: maxConcurrent,
          );
        });
      }
    }

    print('Starting downloads with a concurrency limit of $maxConcurrent...');
    processQueue();
    await queueEmptyCompleter.future;

    return lastImageUrl!;
  } catch (e) {
    print('Error downloading images: $e');
    throw Exception('Failed to download images');
  }
}

Future<void> updateInstalltionAfterFullRefreshofImages(
    String lastImageUrl, String username) async {
  if (lastImageUrl != null) {
    print('All images downloaded! Last downloaded image: $lastImageUrl');
    final logDateTime = await logButtonAction(lastImageUrl!, username);
    if (logDateTime != null) {
      await updateAppInstallationRecord(username, logDateTime);
    }
  } else {
    print('No images were downloaded.');
  }
}

/// Logs a button action to Firestore.
/// Logs the installation ID, username, image URL, and timestamp for each Add image button action.
/// This function is called when the user adds an image to the board.
/// This is also called when full refresh is done to log the last image downloaded.
/// Logs the button action to Firestore and retrieves the exact server timestamp.
Future<DateTime?> logButtonAction(String imageUrl, String username) async {
  try {
    // Initialize Firebase App Installation ID
    String installationId = await FirebaseInstallations.instance.getId();
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Create a new document in the button_log collection
    DocumentReference docRef = await db.collection('button_log').add({
      'installationId': installationId, // Unique installation ID
      'username': username, // Username of the user
      'image_url': imageUrl, // Image URL of the button
      'datetime': FieldValue.serverTimestamp(), // Firebase server timestamp
    });

    // Fetch the logged document to get the exact server timestamp
    DocumentSnapshot loggedDoc = await docRef.get();
    Timestamp? serverTimestamp = loggedDoc['datetime'] as Timestamp?;

    if (serverTimestamp != null) {
      DateTime exactTime = serverTimestamp.toDate();
      print(
          'Button action logged successfully for image "$imageUrl", downloaded for installation "$installationId", for user "$username".');
      print('Exact server timestamp retrieved: $exactTime');
      return exactTime;
    } else {
      throw Exception('Failed to retrieve server timestamp from Firestore.');
    }
  } catch (e) {
    print('Error logging button action: $e');
    return null; // Return null in case of an error
  }
}

Future<void> processButtonLogs(String username, String childId,
    Timestamp appInstallationTimestamp, bool forChild) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Fetch button logs where datetime is greater than the app installation update timestamp thats get updated after last download of images
  print('Processing button logs for $username');
  final QuerySnapshot buttonLogsSnapshotwithtime = await db
      .collection('button_log')
      .where('username', isEqualTo: username)
      .where('datetime', isGreaterThan: appInstallationTimestamp)
      .get();

  if (buttonLogsSnapshotwithtime.docs.isEmpty) {
    print(
        'No button logs found for the given criteria that means no to image to download.');
    return;
  }
  String imageUrl = '';
  // Loop through each button log and download the image
  for (var doc in buttonLogsSnapshotwithtime.docs) {
    imageUrl = doc['image_url'] as String;
    print('Downloading image from: $imageUrl');

    try {
      await downloadBoardImage(imageUrl, childId, forChild);
      print('Image downloaded successfully: $imageUrl');
    } catch (e) {
      print('Error downloading image from $imageUrl: $e');
    }
  }
  DateTime? logDateTime = await logButtonAction(imageUrl, username);

  if (logDateTime != null) {
    await updateAppInstallationRecord(username, logDateTime);
  } else {
    print('logDateTime is null, skipping updateAppInstallationRecord.');
  }

  print('All button log images processed.');
}

/// Updates the app installation record in Firestore to reflect the last time the app was updated for images or MP3s.
Future<void> updateAppInstallationRecord(
  String username,
  DateTime lastDownloadTime, {
  bool mp3 = false, // Optional parameter with a default value
}) async {
  try {
    // Get the Firebase App Installation ID
    String installationId = await FirebaseInstallations.instance.getId();
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Fetch the app installation record for the user and installation ID
    final QuerySnapshot appInstallationsSnapshot = await db
        .collection('app_installations')
        .where('installationId', isEqualTo: installationId)
        .where('username', isEqualTo: username)
        .get();

    if (appInstallationsSnapshot.docs.isEmpty) {
      print(
          'No app installation record found for this user and installation ID. Creating a new record.');

      // Create a new app installation record
      await db.collection('app_installations').add({
        'installationId': installationId,
        'username': username,
        'timestamp': lastDownloadTime,
        'mp3_processed': mp3,
        'last_mp3_download': mp3 ? lastDownloadTime : null,
      });

      print('App installation record created successfully.');
    } else {
      print(
          'App installation record already exists. Updating the timestamp to reflect the last time the app was updated.');

      // Update the app installation record
      final updateData = {
        'timestamp': lastDownloadTime,
        if (mp3) 'mp3_processed': true,
        if (mp3) 'last_mp3_download': lastDownloadTime,
      };

      await db
          .collection('app_installations')
          .doc(appInstallationsSnapshot.docs.first.id)
          .update(updateData);

      print('App installation record updated successfully.');
    }
  } catch (e) {
    print('Error updating app installation record: $e');
  }
}

Future<DateTime?> logMp3Download(
    String mp3Url, String mp3coverimageurl, String username) async {
  try {
    // Initialize Firebase App Installation ID
    String installationId = await FirebaseInstallations.instance.getId();
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Create a new document in the button_log collection
    DocumentReference docRef = await db.collection('mp3_log').add({
      'installationId': installationId, // Unique installation ID
      'username': username, // Username of the user
      'mp3_url': mp3Url, // Image URL of the button
      'coverimage_url': mp3coverimageurl,
      'datetime': FieldValue.serverTimestamp(), // Firebase server timestamp
    });

    // Fetch the logged document to get the exact server timestamp
    DocumentSnapshot loggedDoc = await docRef.get();
    Timestamp? serverTimestamp = loggedDoc['datetime'] as Timestamp?;

    if (serverTimestamp != null) {
      DateTime exactTime = serverTimestamp.toDate();
      print(
          'mp3 action logged successfully for mp3 "$mp3Url", downloaded for installation "$installationId", for user "$username".');
      print('Exact server timestamp retrieved: $exactTime');
      return exactTime;
    } else {
      throw Exception('Failed to retrieve server timestamp from Firestore.');
    }
  } catch (e) {
    print('Error mp3 action: $e');
    return null; // Return null in case of an error
  }
}

Future<void> processMP3Logs(String username, String childId,
    Timestamp appInstallationTimestamp, bool forChild) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  print('Processing mp3 logs for $username');

  // Fetch mp3 logs where datetime is greater than the app installation update timestamp thats get updated after last download of mp3
  final QuerySnapshot mp3LogsSnapshotwithtime = await db
      .collection('mp3_log')
      .where('username', isEqualTo: username)
      .where('datetime', isGreaterThan: appInstallationTimestamp)
      .get();

  if (mp3LogsSnapshotwithtime.docs.isEmpty) {
    print(
        'No mp3 logs found for the given criteria that means no to image to download.');
    return;
  }
  String mp3Url = '';
  String mp3coverimageurl = '';
  // Loop through each button log and download the image
  for (var doc in mp3LogsSnapshotwithtime.docs) {
    mp3Url = doc['mp3_url'] as String;
    mp3coverimageurl = doc['coverimage_url'] as String;
    print('Downloading mp3 from: $mp3Url');

    try {
      downloadMp3(mp3Url, childId, forChild);
      downloadCoverImage(mp3coverimageurl, childId, forChild);

      print('mp3 downloaded successfully: $mp3Url');
    } catch (e) {
      print('Error downloading mp3 from $mp3Url: $e');
    }
  }
  DateTime? logDateTime =
      await logMp3Download(mp3Url, mp3coverimageurl, username);

  if (logDateTime != null) {
    await updateAppInstallationRecord(username, logDateTime, mp3: true);
  } else {
    print('logDateTime is null, skipping updateAppInstallationRecord.');
  }

  print('All mp3 log images processed.');
}

Future<void> downloadMp3FilesConcurrently(
    List<dynamic> musicData, String childId, String username, bool forChild,
    {int maxConcurrent = 3}) async {
  try {
    // A queue to manage the number of active tasks
    print('inside downloadMp3FilesConcurrently');
    final Queue<Future> taskQueue = Queue();
    final Completer<void> queueEmptyCompleter = Completer();
    int activeTasks = 0;

    Future<void> _processQueue() async {
      while (taskQueue.isNotEmpty) {
        if (activeTasks >= maxConcurrent) {
          await Future.delayed(
              const Duration(milliseconds: 50)); // Yield CPU and retry.
          continue;
        }

        final task = taskQueue.removeFirst();
        activeTasks++;
        try {
          await task;
        } catch (e) {
          print('Error processing task: $e');
        } finally {
          activeTasks--;
        }
      }
      queueEmptyCompleter.complete();
    }

    String mp3Url = '';
    String mp3coverimageurl = '';
    // Add tasks to the queue for both MP3 and image downloads
    for (var item in musicData) {
      taskQueue.add(downloadMp3(item['link'], childId, forChild));
      taskQueue.add(downloadCoverImage(item['image'], childId, forChild));
      mp3Url = item['link'];
      mp3coverimageurl = item['image'];
    }

    print(
        'Starting concurrent downloads with a max concurrency of $maxConcurrent...');
    _processQueue(); // Start processing the queue
    await queueEmptyCompleter.future; // Wait until all tasks are processed

    print(
        'All Mp3 downloads completed successfully!  now update installtion record and log the last download time');

    DateTime? lastDownloadTime =
        await logMp3Download(mp3Url, mp3coverimageurl, username);
    if (lastDownloadTime != null) {
      updateAppInstallationRecord(username, lastDownloadTime);
    } else {
      print('Failed to log MP3 download time.');
    }
    if (lastDownloadTime != null) {
      updateAppInstallationRecord(username, lastDownloadTime, mp3: true);
    } else {
      print('Failed to log MP3 download time.');
    }
  } catch (e) {
    print('Error during concurrent downloads: $e');
  }
}

/// Refreshes the grid from the latest board images and logs the last image downloaded.
Future<void> refreshGridFromLatestBoard(BuildContext context, String username,
    String childId, bool forChild) async {
  try {
    // Get the Firebase App Installation ID
    String installationId = await FirebaseInstallations.instance.getId();
    final FirebaseFirestore db = FirebaseFirestore.instance;

    print('Fetching last updates for $username and $installationId');

    // Fetch the app installation record for the user and installation ID
    final QuerySnapshot appInstallationsSnapshot = await db
        .collection('app_installations')
        .where('installationId', isEqualTo: installationId)
        .where('username', isEqualTo: username)
        .get();

    // Get the timestamp of the app installation
    Timestamp appInstallationTimestamp =
        appInstallationsSnapshot.docs.first['timestamp'];

    // Process button logs to download images after the app installation timestamp
    await processButtonLogs(
        username, childId, appInstallationTimestamp, forChild);

    final basePageState = context.findAncestorStateOfType<BasePageState>();

    if (basePageState != null) {
      print("BasePageState found. Calling _loadJsonData...");
      basePageState.loadJsonData();
    } else {
      print("BasePageState is null. Cannot call _loadJsonData.");
    }
  } catch (e) {
    print('Error refreshing grid from latest board: $e');
  }
}

Future<void> fetchAndStoreChildrenData(
    String parentId,
    List<dynamic> childrenIds,
    BuildContext context,
    String parentusername,
    bool forChild,
    {bool refreshButtons = false}) async {
  print('inside fetchAndStoreChildrenData');
  final childProvider = Provider.of<ChildProvider>(context, listen: false);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  ChildCollectionWithKeys.instance.dispose();

  for (String childId in childrenIds) {
    DocumentSnapshot childDoc =
        await db.collection('children').doc(childId).get();

    if (childDoc.exists) {
      var childData = childDoc.data() as Map<String, dynamic>;
      String childUsername = childData['username'];
      //  childProvider.setChildData(childId, childData);

      await setChildCollectionWithDecryptedData(parentId, childId, childData);

      //String childUsername = childData['username'];
      if (refreshButtons) {
        try {
          String? boardJsonString =
              await childProvider.fetchJson("board.json", childId);
          final Map<String, dynamic> boardData = json.decode(boardJsonString!);

          print(
              ' inside fetchAndStoreChildrenData calling fetchButtonLogsAndDownloadImages for parent $parentusername and child $childUsername');
          await fetchButtonLogsAndDownloadImages(
              childUsername, childId, boardData["buttons"]!, forChild);
          /*
        String? musicJsonString = await childProvider.fetchJson("music.json");
        final List<dynamic> musicData = json.decode(musicJsonString!);

        for (int i = 0; i < musicData.length; i++) {
          await downloadMp3(musicData[i]['link']);
          await downloadCoverImage(musicData[i]['image']);
        }*/
        } catch (e) {
          print(e);
        }
      }
      print('end of fetchAndStoreChildrenData');
    }
  }
}

/// Copies an MP3 file from local assets to a local folder with `childId` in the path.
/// Skips if the file already exists.
Future<File?> copyMp3ToLocalFolder(String fileName, String childId) async {
  try {
    print('Attempting to download MP3: $fileName for childId: $childId');

    // Get the application directory
    final directory = await getApplicationDocumentsDirectory();

    // Define the file path with `childId` in the folder structure
    final filePath =
        '${directory.path}/$childId/music_info/mp3 files/$fileName';
    final file = File(filePath);

    // Skip if the file already exists
    if (await file.exists()) {
      print('MP3 file already exists at: $filePath');
      return file;
    }

    // Load the asset file
    final byteData = await rootBundle.load('assets/songs/$fileName');

    // Ensure the directory exists
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Write the file locally
    await file.writeAsBytes(byteData.buffer.asUint8List());
    print('MP3 file saved to: $filePath');

    return file;
  } catch (e) {
    print('Error downloading MP3: $e');
    return null;
  }
}

/// Copies a cover image from local assets to a local folder with `childId` in the path.
/// Skips if the file already exists.
Future<File?> copyCoverImagetoLocalFolder(
    String fileName, String childId) async {
  try {
    print(
        'Attempting to download cover image: $fileName for childId: $childId');

    // Get the application directory
    final directory = await getApplicationDocumentsDirectory();

    // Define the file path with `childId` in the folder structure
    final filePath =
        '${directory.path}/$childId/music_info/cover_images/$fileName';
    final file = File(filePath);

    // Skip if the file already exists
    if (await file.exists()) {
      print('Cover image already exists at: $filePath');
      return file;
    }

    // Load the asset file
    final byteData = await rootBundle.load('assets/songs/$fileName');

    // Ensure the directory exists
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Write the file locally
    await file.writeAsBytes(byteData.buffer.asUint8List());
    print('Cover image saved to: $filePath');

    return file;
  } catch (e) {
    print('Error downloading cover image: $e');
    return null;
  }
}

/// Loads and parses music metadata from the JSON file.
Future<List<dynamic>> loadMusicMetadata() async {
  try {
    print('Loading music metadata from JSON...');
    final jsonString = await rootBundle.loadString('assets/songs/music.json');
    return jsonDecode(jsonString) as List<dynamic>;
  } catch (e) {
    print('Error loading music metadata: $e');
    return [];
  }
}

Future<void> copyMusicToLocalHolderFromAsset(String childId) async {
  final musicData = await loadMusicMetadata();

  for (var item in musicData) {
    final mp3FileName = item['link'];
    final imageFileName = item['image'];

    // Download the MP3 file
    final mp3File = await copyMp3ToLocalFolder(mp3FileName, childId);
    if (mp3File != null) {
      print('MP3 file processed: ${mp3File.path}');
    }

    // Download the cover image
    final imageFile = await copyCoverImagetoLocalFolder(imageFileName, childId);
    if (imageFile != null) {
      print('Image file processed: ${imageFile.path}');
    }
  }
}

Future<void> copyAllAssetsToAppFolder(String childId) async {
  // Get the application directory
  final directory = await getApplicationDocumentsDirectory();

  // Create the child-specific board_images directory
  final String childBoardDirectory =
      p.join(directory.path, childId, 'board_images');
  final childBoardDir = Directory(childBoardDirectory);

  if (!await childBoardDir.exists()) {
    await childBoardDir.create(recursive: true);
  }

  // Load the list of asset paths from the JSON file
  final assetListString = await rootBundle.loadString('assets/asset_list.json');
  final List<String> assetPaths =
      List<String>.from(json.decode(assetListString));

  // List to store the Future objects for concurrency
  List<Future<void>> futures = [];

  for (String assetPath in assetPaths) {
    print('Copying asset: $assetPath');

    // Construct the path to the specific child directory
    final filePath = p.join(childBoardDirectory, p.basename(assetPath));
    final file = File(filePath);

    if (await file.exists()) {
      print('Skipping $filePath, file already exists');
      continue;
    }

    // Add the task to the futures list
    futures.add(Future(() async {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List());
      print('Copied $filePath');
    }));
  }

  // Wait for all tasks to complete
  await Future.wait(futures);
}

/// Deletes a folder and all its contents from Firebase Storage and the local file system.
/// Skips deletion if the folder does not exist.
Future<void> deleteFolder(String folderPath) async {
  try {
    // Initialize Firebase Storage instance
    final FirebaseStorage storage = FirebaseStorage.instance;

    // Get a reference to the folder
    Reference folderRef = storage.ref(folderPath);

    // Attempt to list all files and subfolders within the folder
    ListResult result;
    try {
      result = await folderRef.listAll();
    } catch (e) {
      print(
          'Folder $folderPath does not exist in Firebase Storage. Skipping deletion.');
      return; // Exit if the folder does not exist
    }

    // Delete all files in the folder
    for (Reference fileRef in result.items) {
      try {
        await fileRef.delete();
        print('Deleted file: ${fileRef.fullPath}');
      } catch (e) {
        print('Error deleting file ${fileRef.fullPath}: $e');
      }
    }

    // Recursively delete all subfolders
    for (Reference subfolderRef in result.prefixes) {
      await deleteFolder(subfolderRef.fullPath);
    }

    // Delete the folder itself
    try {
      await folderRef.delete();
      print('Folder $folderPath deleted successfully from Firebase Storage.');
    } catch (e) {
      print('Error deleting folder $folderPath: $e');
    }

    // Delete the corresponding local folder
    final directory = Directory.systemTemp;
    final localFolder = Directory('${directory.path}/$folderPath');

    if (await localFolder.exists()) {
      try {
        await localFolder.delete(recursive: true);
        print('Local folder $folderPath deleted successfully.');
      } catch (e) {
        print('Error deleting local folder $folderPath: $e');
      }
    } else {
      print('Local folder $folderPath does not exist. Skipping deletion.');
    }
  } catch (e) {
    print('Error deleting folder $folderPath: $e');
    throw Exception('Failed to delete folder $folderPath.');
  }
}

/// Deletes a local folder and its contents for a specific child ID.
/// Skips deletion if the folder does not exist.
Future<void> deleteLocalChildFolder(String childId) async {
  try {
    // Get the application directory
    final directory = await getApplicationDocumentsDirectory();

    // Construct the path for the child-specific folder
    final String childFolderPath = p.join(directory.path, childId);
    final Directory childFolder = Directory(childFolderPath);

    // Check if the directory exists
    if (await childFolder.exists()) {
      try {
        // Recursively delete the folder and its contents
        await childFolder.delete(recursive: true);
        print('Local folder deleted successfully: $childFolderPath');
      } catch (e) {
        print('Error deleting contents of local folder $childFolderPath: $e');
      }
    } else {
      print(
          'Local folder does not exist: $childFolderPath. Skipping deletion.');
    }
  } catch (e) {
    print('Error deleting local folder: $e');
    throw Exception('Failed to delete local folder for child $childId.');
  }
}
