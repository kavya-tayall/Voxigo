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
      bool byChild = byParent ? false : true;
      // Decrypt the selected data for the child
      List<dynamic> decryptedButtons = await decryptSelectedDataForChild(
          childId, selectedButtons,
          byChild: byChild);
      List<dynamic> decryptedFeelings = await decryptSelectedDataForChild(
          childId, selectedFeelings,
          byChild: byChild);

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

Future<void> fetchSingleChildBoardData(BuildContext context, bool forChild,
    {String? childIdPassed, // Optional parameter with null safety
    String? childUsernamePassed}) async {
  try {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    // Fetch child username from provider
    String? childUsername =
        (childUsernamePassed != null && childUsernamePassed.isNotEmpty)
            ? childUsernamePassed
            : childProvider.childData?['username'];

    // Determine the child ID to use
    String? childId = (childIdPassed != null && childIdPassed.isNotEmpty)
        ? childIdPassed
        : childProvider.childId;

    if (childId == null || childId.isEmpty) {
      throw Exception("Child ID is not provided or invalid.");
    }

    // Fetch and process board.json
    String? boardJsonString =
        await childProvider.fetchJson("board.json", childId);
    if (boardJsonString == null) {
      throw Exception("Failed to fetch board.json for child ID: $childId");
    }

    final Map<String, dynamic> boardData = json.decode(boardJsonString);

    print(
        'Inside fetchSingleChildData now calling fetchButtonLogsAndDownloadImagesForSingleChild for $childUsername');

    // Step 1: Fetch all the images from board.json and download them as per the last update in button log
    await fetchButtonLogsAndDownloadImagesForSingleChild(
      childUsername!,
      childId,
      boardData["buttons"]!,
      forChild,
    );

    // Step 2: Fetch and process music.json (if required)
    // fetchMusicFiles(context); -- commenting this code for optimization
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
Future<void> fetchButtonLogsAndDownloadImagesForSingleChild(
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

Future<void> fetchAndStoreAllChildrenDataForParent(String parentId,
    String childId, BuildContext context, bool forChild, Timestamp timestamp,
    {bool refreshButtons = false, bool disposeChildCollection = false}) async {
  print('inside fetchAndStoreAllChildrenDataForParent');
  final FirebaseFirestore db = FirebaseFirestore.instance;

  DocumentSnapshot childDoc =
      await db.collection('children').doc(childId).get();

  if (childDoc.exists) {
    var childData = childDoc.data() as Map<String, dynamic>;

    await setChildCollectionWithDecryptedData(
        parentId, childId, childData, timestamp);

    if (refreshButtons) {
      await fetchSingleChildBoardData(context, forChild,
          childIdPassed: childId);
    }
    print('end of fetchAndStoreAllChildrenDataForParent');
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

  final String localImagePath = '${directory.path}/fallback_image.png';

  // Check if the file already exists
  if (!File(localImagePath).existsSync()) {
    // Read the image data from the asset bundle
    final ByteData data =
        await rootBundle.load('assets/imgs/fallback_image.png');
    final buffer = data.buffer;

    // Write the image data to the local file
    await File(localImagePath).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

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

Future<void> updateParentChildrenFieldold(
    String parentId, String childId) async {
  try {
    print('inside updateParentChildrenField');
    // Reference to the parent document
    final parentRef =
        FirebaseFirestore.instance.collection('parents').doc(parentId);

    // Get the current data of the parent document
    DocumentSnapshot parentSnapshot = await parentRef.get();

    if (parentSnapshot.exists) {
      Map<String, dynamic>? parentData =
          parentSnapshot.data() as Map<String, dynamic>?;

      // Initialize or update the `ChildrenList` field
      List<dynamic> childrenList = parentData?['ChildrenList'] ?? [];

      // Check if the child already exists in the list
      int index =
          childrenList.indexWhere((child) => child['ChildId'] == childId);

      if (index != -1) {
        // Update the existing child's timestamp
        childrenList[index]['LastUpdatedTimeStamp'] =
            FieldValue.serverTimestamp();
      } else {
        // Add a new entry for the child
        childrenList.add({
          'ChildId': childId,
          'LastUpdatedTimeStamp': FieldValue.serverTimestamp(),
        });
      }

      // Update the parent document with the updated ChildrenList
      await parentRef.update({'ChildrenList': childrenList});
      print('Parent Children field updated successfully!');
    }
  } catch (e) {
    print('Error updating parent Children field: $e');
  }
}

Future<void> updateParentChildrenField(String parentId, String childId) async {
  try {
    print('inside updateParentChildrenField');
    // Reference to the parent document
    final parentRef =
        FirebaseFirestore.instance.collection('parents').doc(parentId);
    DocumentSnapshot updatedParentSnapshot = await parentRef.get();

    Map<String, dynamic>? parentData =
        updatedParentSnapshot.data() as Map<String, dynamic>?;
    List<dynamic> childrenList = parentData?['ChildrenList'] ?? [];

    // Check if the child already exists in the list
    int index = childrenList.indexWhere((child) => child['ChildId'] == childId);

    if (index != -1) {
      // Update the existing child's LastUpdatedTimeStamp
      childrenList[index] = {
        'ChildId': childId,
        'LastUpdatedTimeStamp':
            Timestamp.now(), // Use Timestamp.now() for consistency
      };
    } else {
      // Add a new entry for the child
      childrenList.add({
        'ChildId': childId,
        'LastUpdatedTimeStamp': Timestamp.now(),
      });
    }

    // Update the parent document with the modified ChildrenList
    await parentRef.update({'ChildrenList': childrenList});
    print('ChildrenList updated successfully.');
  } catch (e) {
    print('Error while adding or updating child to parent: $e');
  }
}

Future<void> removeChildFromParentField(String parentId, String childId) async {
  try {
    print('inside removeChildFromParentField');
    // Reference to the parent document
    final parentRef =
        FirebaseFirestore.instance.collection('parents').doc(parentId);
    DocumentSnapshot updatedParentSnapshot = await parentRef.get();

    Map<String, dynamic>? parentData =
        updatedParentSnapshot.data() as Map<String, dynamic>?;
    List<dynamic> childrenList = parentData?['ChildrenList'] ?? [];

    // Find the child in the list and remove it
    int index = childrenList.indexWhere((child) => child['ChildId'] == childId);

    if (index != -1) {
      // Remove the child from the list
      childrenList.removeAt(index);
      // Update the parent document with the modified ChildrenList
      await parentRef.update({'ChildrenList': childrenList});
      print('Child removed successfully.');
    } else {
      print('Child not found in the list.');
    }
  } catch (e) {
    print('Error while removing child from parent: $e');
  }
}

Future<void> refreshChildCollection(
    BuildContext context, String parentId) async {
// Fetch the parent document
  DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
      .collection('parents')
      .doc(parentId)
      .get();

  if (parentSnapshot.exists) {
    Map<String, dynamic>? parentData =
        parentSnapshot.data() as Map<String, dynamic>?;

    List<dynamic> oldChildIdList = parentData?['children'] ?? [];

    if (parentData != null && parentData['ChildrenList'] == null) {
      print('old style of children list');
      for (var childIds in oldChildIdList) {
        print(
            'calling old style fetchAndStoreAllChildrenDataForParent for child IDs: $childIds');
        await fetchAndStoreAllChildrenDataForParent(
          parentId,
          childIds,
          context,
          true,
          Timestamp.now(),
          refreshButtons: true,
        );
      }
      return;
    }

    if (parentData != null && parentData['ChildrenList'] != null) {
      // Retrieve the child data from the ChildrenList in the parent document
      List<dynamic> childrenList = List.from(parentData['ChildrenList']);
      print(' new style of child list inside _buildChildCollectionForParent');

      for (var childEntry in childrenList) {
        String childId = childEntry['ChildId'];
        Timestamp? timestampfromdb = childEntry['Timestamp'];

        // Fetch the child record using ChildCollectionWithKeys.instance.getRecord(childId)
        ChildRecord childRecord =
            ChildCollectionWithKeys.instance.getRecord(childId) as ChildRecord;

        // Check if the child record's username is empty or the timestamp is older than the current timestamp

        String username = childRecord.username ?? '';
        Timestamp recordtimestamp = childRecord.timestamp ?? Timestamp.now();

        // Check the conditions
        if (username == '' ||
            (timestampfromdb != null &&
                recordtimestamp.compareTo(timestampfromdb) < 0)) {
          // Call your method here if conditions are met
          timestampfromdb = timestampfromdb ?? Timestamp.now();
          print(
              'Calling fetchAndStoreAllChildrenDataForParent for child IDs: $childId');

          // For example, call the method `fetchAndStoreAllChildrenDataForParent`
          await fetchAndStoreAllChildrenDataForParent(
            parentId,
            childId,
            context,
            true,
            timestampfromdb!,
            refreshButtons: false,
          );
        }
      }
    }
  }
}
