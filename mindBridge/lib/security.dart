import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';
import 'package:test_app/auth_logic.dart';
import 'dart:math';
import 'package:test_app/getauthtokenandkey.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:test_app/widgets/child_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Uint8List generateSecureRandomKey(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(length, (_) => random.nextInt(256)),
  );
}

/// Decrypts the provided encrypted data using AES-CBC with PKCS7 padding.
///
/// [data] - The encrypted data to decrypt.
/// [key] - The AES key (16, 24, or 32 bytes).
/// [iv] - The initialization vector (16 bytes).
///
/// Returns the decrypted plaintext data as a [Uint8List].
Uint8List decryptData(Uint8List data, Uint8List key, Uint8List iv) {
  // Validate key and IV sizes
  if (key.length != 16 && key.length != 24 && key.length != 32) {
    throw ArgumentError('Invalid AES key size. Must be 16, 24, or 32 bytes.');
  }
  if (iv.length != 16) {
    throw ArgumentError('Invalid IV size. Must be 16 bytes.');
  }

  try {
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false, // false for decryption
        PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
          ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
          null,
        ),
      );

    return cipher.process(data);
  } catch (e) {
    throw Exception('Decryption failed: $e');
  }
}

Uint8List generateIV() {
  final random = Random.secure();
  return Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
}

Future<Uint8List> getEncryptionKey(
    {bool forChild = false, String childId = ''}) async {
  final session = UserSession.instance;

  // Check if the user is a parent and the key is for a child
  if (session.userType == UserType.parent && forChild) {
    if (childId.isEmpty) {
      throw Exception('Child ID must be provided when forChild is true.');
    }
    final ChildCollectionWithKeys childCollection =
        ChildCollectionWithKeys.instance;
    Uint8List? key = childCollection.getkey(childId);

    if (key == null) {
      throw Exception('No secure key found for the child with ID: $childId.');
    }
    return key;
  } else {
    Uint8List? storedKey = session.secureKey;
    if (storedKey == null) {
      throw Exception('No secure key found for the session.');
    }
    return storedKey;
  }
}

Uint8List aesGcmEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
  final encrypter = encrypt.Encrypter(encrypt.AES(
    encrypt.Key(key),
    mode: encrypt.AESMode.gcm,
  ));
  final encrypted = encrypter.encryptBytes(data, iv: encrypt.IV(iv));
  return encrypted.bytes;
}

Uint8List aesGcmDecrypt(Uint8List encryptedData, Uint8List key, Uint8List iv) {
  final encrypter = encrypt.Encrypter(encrypt.AES(
    encrypt.Key(key),
    mode: encrypt.AESMode.gcm,
  ));
  return Uint8List.fromList(encrypter.decryptBytes(
    encrypt.Encrypted(encryptedData),
    iv: encrypt.IV(iv),
  ));
}

Future<Map<String, String>> encryptTextWithIV(String text) async {
  // Step 1: Fetch encryption key from the API
  Uint8List key = await getEncryptionKey();

  // Step 2: Generate a secure IV
  Uint8List iv = generateIV();

  // Step 3: Encrypt the text
  Uint8List textBytes = Uint8List.fromList(utf8.encode(text));
  Uint8List encryptedBytes = aesGcmEncrypt(textBytes, key, iv);

  // Step 4: Encode the encrypted text and IV for storage/transmission
  String encryptedText = base64Encode(encryptedBytes);
  String encodedIV = base64Encode(iv);

  print("Original Text: $text");
  print("Encrypted Text (Base64): $encryptedText");

  return {'text': encryptedText, 'iv': encodedIV};
}

Future<Map<String, String>> encryptParentInfoWithIV(String parentId,
    String username, String email, String firstname, String lastname) async {
  Uint8List key = await getEncryptionKey();
  print("Fetched Key (Base64): ${base64Encode(key)}");

  Uint8List iv = generateIV();
  print("Generated IV (Base64): ${base64Encode(iv)}");

  Uint8List textBytes = Uint8List.fromList(utf8.encode(username));
  Uint8List encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedUsername = base64Encode(encryptedBytes);

  textBytes = Uint8List.fromList(utf8.encode(email));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedEmail = base64Encode(encryptedBytes);

  textBytes = Uint8List.fromList(utf8.encode(firstname));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedFirstname = base64Encode(encryptedBytes);

  textBytes = Uint8List.fromList(utf8.encode(lastname));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedLastname = base64Encode(encryptedBytes);

  String encodedIV = base64Encode(iv);

  return {
    'username': encryptedUsername,
    'email': encryptedEmail,
    'firstname': encryptedFirstname,
    'lastname': encryptedLastname,
    'iv': encodedIV,
  };
}

Future<Map<String, String>> encryptChildInfoWithIV(
  String parentId,
  String childId,
  String username,
  String firstname,
  String lastname,
  String childtheme,
  String mode,
) async {
  Uint8List key;
  Uint8List iv;
  ChildSettings childSettings;

// get Key and IV for child
  print('mode: $mode');
  if (mode == "add") {
    // get new key when adding a child
    key = await getChildKey(parentId, childId, mode: mode);
    iv = generateIV();
    childSettings = ChildSettings(
      childuid: childId,
      childsecureKey: key,
      childbaserecordiv: iv,
      audioPage: true,
      emotionHandling: true,
      gridEditing: true,
      sentenceHelper: true,
    );
  } else {
    // get existing key from the collection when editing a child
    final childCollection = ChildCollectionWithKeys.instance;
    key = childCollection.getkey(childId) ??
        (throw Exception('Encryption key not found for childId: $childId'));

    ChildRecord childRecord = childCollection.getRecord(childId) ??
        (throw Exception('Record not found for childId: $childId'));
    iv = childRecord.childbaserecordiv!;

    childSettings = childRecord.settings ??
        ChildSettings(
          childuid: childId,
          childsecureKey: key,
          childbaserecordiv: iv,
          audioPage: true,
          emotionHandling: true,
          gridEditing: true,
          sentenceHelper: true,
        );
  }
  String encodedIV = base64Encode(iv);
  print('encodedIV: $base64Encode(iv)');

  // Encrypt firstname
  Uint8List textBytes = Uint8List.fromList(utf8.encode(firstname));
  Uint8List encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedFirstname = base64Encode(encryptedBytes);

  // Encrypt lastname
  textBytes = Uint8List.fromList(utf8.encode(lastname));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedLastname = base64Encode(encryptedBytes);

  // Username remains unencrypted
  String encryptedUsername = username;

  // Determine settings
  bool audioPage = mode == "add" ? true : childSettings?.audioPage ?? true;
  bool emotionHandling =
      mode == "add" ? true : childSettings?.emotionHandling ?? true;
  bool gridEditing = mode == "add" ? true : childSettings?.gridEditing ?? true;
  bool sentenceHelper =
      mode == "add" ? true : childSettings?.sentenceHelper ?? true;

  // Encrypt settings
  textBytes = Uint8List.fromList(utf8.encode(audioPage.toString()));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedaudioPage = base64Encode(encryptedBytes);

  textBytes = Uint8List.fromList(utf8.encode(emotionHandling.toString()));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedemotionHandling = base64Encode(encryptedBytes);

  textBytes = Uint8List.fromList(utf8.encode(gridEditing.toString()));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedgridEditing = base64Encode(encryptedBytes);

  textBytes = Uint8List.fromList(utf8.encode(sentenceHelper.toString()));
  encryptedBytes = aesGcmEncrypt(textBytes, key, iv);
  String encryptedsentenceHelper = base64Encode(encryptedBytes);

  // Create ChildSettings object
  ChildSettings finalChildSettings = ChildSettings(
    childuid: childId,
    childsecureKey: key,
    childbaserecordiv: iv,
    audioPage: audioPage,
    emotionHandling: emotionHandling,
    gridEditing: gridEditing,
    sentenceHelper: sentenceHelper,
  );

  // Add or update the record in the collection
  final childCollection = ChildCollectionWithKeys.instance;
  childCollection.addOrUpdateChildData(
    childId,
    key,
    iv,
    username,
    firstname,
    lastname,
    childtheme,
    finalChildSettings,
  );

  return {
    'username': encryptedUsername,
    'first name': encryptedFirstname,
    'last name': encryptedLastname,
    'iv': encodedIV,
    'settings': jsonEncode({
      'audio page': encryptedaudioPage,
      'emotion handling': encryptedemotionHandling,
      'grid editing': encryptedgridEditing,
      'sentence helper': encryptedsentenceHelper,
      'theme': childtheme,
    }),
  };
}

Future<Map<String, String>?> decryptParentDetails(String userId) async {
  try {
    print('decryptParentDetails userId: $userId');

    // Fetch parent data from Firestore using the userId
    DocumentSnapshot parentResult = await FirebaseFirestore.instance
        .collection('parents')
        .doc(userId)
        .get();

    print('parentResult: ${parentResult.data()}');
    if (!parentResult.exists) {
      print('parentSnapshot does not exist');
      return null; // Return null if no document is found
    }

    // Safely get the data as a map
    Map<String, dynamic>? parentData =
        parentResult.data() as Map<String, dynamic>?;

    // Initialize variables with null if the fields don't exist
    String? encodedIV =
        parentData?.containsKey('iv') == true ? parentData!['iv'] : null;
    String? encryptedEmail =
        parentData?.containsKey('email') == true ? parentData!['email'] : null;
    String? encryptedUsername = parentData?.containsKey('username') == true
        ? parentData!['username']
        : null;

    String? encryptedFirstName = parentData?.containsKey('firstname') == true
        ? parentData!['firstname']
        : null;
    String? encryptedLastName = parentData?.containsKey('lastname') == true
        ? parentData!['lastname']
        : null;

    print('so far so good');
    print('encryptedEmail: $encryptedEmail');
    print('encryptedUsername: $encryptedUsername');

    print('encryptedFirstName: $encryptedFirstName');
    print('encryptedLastName: $encryptedLastName');

    // Prepare the result map
    Map<String, String> decryptedDetails = {};

    // Check if IV is missing or empty
    if (encodedIV == null || encodedIV.trim().isEmpty) {
      // If IV is missing, just return email directly (assuming no encryption)

      if (encryptedEmail == null || encryptedEmail.trim().isEmpty) {
        print("Email is missing or empty.");
      } else {
        decryptedDetails['email'] =
            encryptedEmail; // Email is not encrypted, return directly
        print("Email (not encrypted): $encryptedEmail");
      }

      // Similarly, if no IV, check for name and username (if present)
      if (encryptedUsername != null && encryptedUsername.trim().isNotEmpty) {
        decryptedDetails['username'] = encryptedUsername;
        print("Username (not encrypted): $encryptedUsername");
      }

      if (encryptedFirstName != null && encryptedFirstName.trim().isNotEmpty) {
        decryptedDetails['firstname'] = encryptedFirstName;
        print("Name (not encrypted): $encryptedFirstName");
      }
      if (encryptedLastName != null && encryptedLastName.trim().isNotEmpty) {
        decryptedDetails['lastname'] = encryptedLastName;
        print("Name (not encrypted): $encryptedLastName");
      }
    } else {
      // If IV is present, proceed with decryption for all fields
      print("IV is not null");

      // Decode the IV
      Uint8List iv = base64Decode(encodedIV);

      // Fetch the key for decryption
      Uint8List key = await getEncryptionKey();
      print("Key: ${base64Encode(key)}");
      decryptedDetails['key'] = base64Encode(key);
      decryptedDetails['iv'] = encodedIV;

      // Decrypt the email if it's encrypted
      if (encryptedEmail != null && encryptedEmail.trim().isNotEmpty) {
        print("Encrypted email exists, proceeding with decryption...");
        Uint8List encryptedBytes = base64Decode(encryptedEmail);
        String decryptedEmail =
            utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));
        decryptedDetails['email'] = decryptedEmail;
        print("Decrypted Email: $decryptedEmail");
      }

      // Decrypt the username if it's encrypted
      if (encryptedUsername != null && encryptedUsername.trim().isNotEmpty) {
        print("Encrypted username exists, proceeding with decryption...");
        Uint8List encryptedBytes = base64Decode(encryptedUsername);
        String decryptedUsername =
            utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));
        decryptedDetails['username'] = decryptedUsername;
        print("Decrypted Username: $decryptedUsername");
      }

      // Decrypt the firstname if it's encrypted
      if (encryptedFirstName != null && encryptedFirstName.trim().isNotEmpty) {
        print("Encrypted firstname exists, proceeding with decryption...");
        Uint8List encryptedBytes = base64Decode(encryptedFirstName);
        String decryptedFirstName =
            utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));
        decryptedDetails['firstname'] = decryptedFirstName;
        print("Decrypted Firstname: $decryptedFirstName");
      }

      // Decrypt the lastname if it's encrypted
      if (encryptedLastName != null && encryptedLastName.trim().isNotEmpty) {
        print("Encrypted lastname exists, proceeding with decryption...");
        Uint8List encryptedBytes = base64Decode(encryptedLastName);
        String decryptedLastName =
            utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));
        decryptedDetails['lastname'] = decryptedLastName;
        print("Decrypted Lastname: $decryptedLastName");
      }
    }

    // Return the decrypted details as a map
    return decryptedDetails;
  } catch (e) {
    print("Error fetching parent data: $e");
    return null; // Return null if an error occurs
  }
}

Future<List<dynamic>> decryptSelectedDataForChild(
    String childId, List<dynamic> encryptedButtons,
    {bool byChild = false}) async {
  try {
    Uint8List? childkey;
    // Fetch the encryption key
    if (byChild) {
      childkey = await getEncryptionKey(forChild: true, childId: childId);
    } else {
      final childCollection = ChildCollectionWithKeys.instance;
      print('childId: $childId');

      childkey = childCollection.getkey(childId);
    }

    Uint8List? key = childkey;

    if (key == null) {
      throw Exception('Encryption key not found for childId: $childId');
    }
    // Decrypt each button's text
    return encryptedButtons.map((item) {
      String encryptedText = item['text'];
      String encodedIV = item['iv'];

      // Decode the IV and encrypted text
      Uint8List iv = base64Decode(encodedIV);
      Uint8List encryptedBytes = base64Decode(encryptedText);

      print('Decryption here Key: ${base64.encode(key)}');
      print('IV: ${base64.encode(iv)}');
      print('Encrypted Data: ${base64.encode(encryptedBytes)}');

      // Decrypt the text
      String decryptedText =
          utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));

      // Replace the text with its decrypted value
      return {
        ...item,
        'text': decryptedText,
      };
    }).toList();
  } catch (e) {
    print('Error decrypting selected buttons: $e');
    return encryptedButtons; // Return the original list in case of an error
  }
}

Future<List<dynamic>> decryptSelectedDataForChildtmp(
    String childId, List<dynamic> selectedDataItems) async {
  try {
    // Fetch the encryption key
    final childCollection = ChildCollectionWithKeys.instance;
    print('Child ID: $childId');
    Uint8List? key = childCollection.getkey(childId);

    if (key == null) {
      throw Exception('Encryption key not found for childId: $childId');
    }

    return selectedDataItems.map((item) {
      // Ensure the structure is valid
      if (item['data'] == null ||
          item['data']['text'] == null ||
          item['data']['iv'] == null) {
        throw Exception('Invalid item format: missing "data", "text", or "iv"');
      }

      String encryptedText = item['data']['text'];
      String encodedIV = item['data']['iv'];

      // Decode the IV and encrypted text
      Uint8List iv = base64Decode(encodedIV);
      Uint8List encryptedBytes = base64Decode(encryptedText);

      print(
          'Decryption Details - Key: ${base64.encode(key)}, IV: ${base64.encode(iv)}, Encrypted Data: ${base64.encode(encryptedBytes)}');

      // Decrypt the text
      String decryptedText =
          utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));

      // Replace the text in the data field with its decrypted value
      return {
        ...item,
        'data': {
          ...item['data'],
          'text': decryptedText, // Decrypted text
        },
      };
    }).toList();
  } catch (e, stackTrace) {
    print('Error decrypting selected feelings items: $e\n$stackTrace');
    return selectedDataItems; // Return the original list in case of an error
  }
}

Future<Uint8List> getChildKey(String parentId, String childId,
    {String mode = ''}) async {
  final apiService = ApiService.instance;

  try {
    // Fetch Firebase token for the child
    final loginUserToken = await getCurrentLoginUserToken();

    // Prepare the request body for the encryption key API
    final requestBodyForKey = {
      'token': loginUserToken,
      'childId': childId,
      if (mode.isNotEmpty) 'mode': mode, // Add mode only if it's provided
    };
    // Fetch the encryption key
    final encryptionKey =
        await apiService.getEncryptionKeyfromVault(requestBodyForKey);

    return encryptionKey;
  } catch (e) {
    // Handle errors
    print('Error while fetching child key: $e');
    throw Exception('Failed to get child key');
  }
}

Future<void> setChildCollectionWithDecryptedData(String parentId,
    String childId, Map<String, dynamic> encryptedChildData) async {
  try {
    String username = '';
    String firstname = '';
    String lastname = '';

    final childCollection = ChildCollectionWithKeys.instance;

    // Fetch the encryption key for the child
    Uint8List encryptionKey = await getChildKey(parentId, childId);

    print('encryptionKey: ${encryptionKey.toString()}');

    // Safely handle `iv` decoding
    Uint8List iv = Uint8List(0); // Default to an empty Uint8List
    if (encryptedChildData.containsKey('iv') &&
        encryptedChildData['iv'] != null) {
      try {
        iv = base64Decode(encryptedChildData['iv']);
        print('iv: ${iv.toString()}');
      } catch (decodeError) {
        print('Error decoding IV: $decodeError');
      }
    } else {
      print('IV not provided or null. Proceeding without IV.');
    }

    if (iv.isEmpty) {
      // If IV is not available, assume fields are not encrypted
      username = encryptedChildData['username'] ?? '';
      firstname = encryptedChildData['first name'] ?? '';
      lastname = encryptedChildData['last name'] ?? '';
    } else {
      // Decrypt the fields
      /* username = await decryptChildfield(
          encryptedChildData['username'], encryptionKey, iv);*/
      username = encryptedChildData['username'];
      firstname = await decryptChildfield(
          encryptedChildData['first name'], encryptionKey, iv);
      lastname = await decryptChildfield(
          encryptedChildData['last name'], encryptionKey, iv);
    }
    //child theme
    String childtheme = 'default';
    childtheme = encryptedChildData?['settings']?['theme'] ?? 'default';
    // Create a ChildSettings object

    ChildSettings childSettings =
        await getChildSettings(childId, encryptionKey, iv);

    // Add or update the record in the collection
    childCollection.addOrUpdateChildData(childId, encryptionKey, iv, username,
        firstname, lastname, childtheme, childSettings);

    print('Record added successfully for childId: $childId');
  } catch (e) {
    // Handle errors
    print('Error while setting child collection with decrypted data: $e');
  }
}

Future<ChildSettings> getChildSettings(
    String childId, Uint8List encryptionKey, Uint8List iv) async {
  bool audioPage = true;
  bool emotionHandling = true;
  bool gridEditing = true;
  bool sentenceHelper = true;

  ChildSettings childSettings = ChildSettings(
    childuid: childId,
    childsecureKey: encryptionKey,
    childbaserecordiv: iv,
    audioPage: audioPage,
    emotionHandling: emotionHandling,
    gridEditing: gridEditing,
    sentenceHelper: sentenceHelper,
  );
  print('getChildSettings for childid: $childSettings' + childId);

  final FirebaseFirestore db = FirebaseFirestore.instance;

  DocumentSnapshot encryptedChildData =
      await db.collection('children').doc(childId).get();

  // Ensure the document exists
  if (!encryptedChildData.exists) {
    print("Child document does not exist for ID: $childId");
    return childSettings;
  }

  if (!encryptedChildData.data().toString().contains('settings') ||
      iv.isEmpty) {
    print('Settings not found');
    return childSettings;
  }

  if (encryptedChildData['settings'] == null || iv.isEmpty) {
    print('Settings not found');
  } else {
    final encryptedaudioPage =
        encryptedChildData?['settings']?['audio page'] ?? 'true';
    final encryptedemotionHandling =
        encryptedChildData?['settings']?['emotion handling'] ?? 'true';
    final encryptedgridEditing =
        encryptedChildData?['settings']?['grid editing'] ?? 'true';
    final encryptedsentenceHelper =
        encryptedChildData?['settings']?['sentence helper'] ?? 'true';

    if (encryptedaudioPage == 'true') {
      print('audioPage is true');
    } else {
      print('encryptedaudioPage: $encryptedaudioPage');
      audioPage =
          await decryptChildfield(encryptedaudioPage, encryptionKey, iv) ==
              'true';
    }

    if (encryptedemotionHandling == 'true') {
      print('emotionHandling is true');
    } else {
      print('encryptedemotionHandling: $encryptedemotionHandling');
      emotionHandling = await decryptChildfield(
              encryptedemotionHandling, encryptionKey, iv) ==
          'true';
    }

    if (encryptedgridEditing == 'true') {
      print('gridEditing is true');
    } else {
      print('encryptedgridEditing: $encryptedgridEditing');
      gridEditing =
          await decryptChildfield(encryptedgridEditing, encryptionKey, iv) ==
              'true';
    }

    if (encryptedsentenceHelper == 'true') {
      print('sentenceHelper is true');
    } else {
      print('encryptedsentenceHelper: $encryptedsentenceHelper');
      sentenceHelper =
          await decryptChildfield(encryptedsentenceHelper, encryptionKey, iv) ==
              'true';
    }
  }

  print('Decryption done');

  childSettings = ChildSettings(
    childuid: childId,
    childsecureKey: encryptionKey,
    childbaserecordiv: iv,
    audioPage: audioPage,
    emotionHandling: emotionHandling,
    gridEditing: gridEditing,
    sentenceHelper: sentenceHelper,
  );

  return childSettings;
}

Future<String> decryptChildfield(
    String encryptedtext, Uint8List key, Uint8List iv) async {
  try {
    // Decrypt the text
    Uint8List encryptedBytes = base64Decode(encryptedtext);
    String decryptedText = utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));

    print('Decrypted Text: $decryptedText');

    return decryptedText;
  } catch (e) {
    // Handle errors
    print('Error decrypting child field: $e');
    throw Exception('Failed to decrypt child field');
  }
}

Future<Map<String, dynamic>> encryptFileContent(
    Uint8List fileContent, bool forChild, String childId) async {
  try {
    // Generate a random IV
    Uint8List iv = generateIV();

    // Retrieve the encryption key
    Uint8List key =
        await getEncryptionKey(forChild: forChild, childId: childId);

    // Encrypt the file content
    Uint8List encryptedContent = aesGcmEncrypt(fileContent, key, iv);

    return {
      'encryptedContent': encryptedContent,
      'iv': iv,
    };
  } catch (e) {
    print("Error encrypting file: $e");
    throw Exception("Failed to encrypt file");
  }
}

Future<Uint8List> decryptFileContent(Uint8List encryptedContent, Uint8List iv,
    bool forChild, String childId) async {
  try {
    // Retrieve the encryption key
    Uint8List key =
        await getEncryptionKey(forChild: forChild, childId: childId);

    // Decrypt the file content
    return aesGcmDecrypt(encryptedContent, key, iv);
  } catch (e) {
    print("Error decrypting file: $e");
    throw Exception("Failed to decrypt file");
  }
}
