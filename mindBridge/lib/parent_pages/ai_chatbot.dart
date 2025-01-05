import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test_app/ai_utility.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:test_app/getauthtokenandkey.dart';
import 'package:test_app/widgets/child_provider.dart';
import '../child_pages/home_page.dart';
import 'package:test_app/security.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/auth_logic.dart';
import 'package:test_app/user_session_management.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatUser user = ChatUser(
    id: '1',
    firstName: 'Charles',
    lastName: 'Leclerc',
  );

  ChatUser aiUser = ChatUser(
    id: '2',
    firstName: 'VoxiBot',
    profileImage: 'assets/imgs/logo_without_text_whitebg.jpg',
  );

  List<ChatMessage> messages = <ChatMessage>[];
  List<ChatUser> typingUsers = [];

  Map<String, Map<String, String>> keywordMap =
      {}; // {keyword: {id: childId, type: fullName/firstName/lastName}}

  Map<String, Map<String, String>> idToKeywordMap =
      {}; // {childId: {fullName: full name, firstName: first name, lastName: last name}}

  void prepareChildIdAndNameMap() async {
    final childCollection = ChildCollectionWithKeys.instance;

    for (ChildRecord childRecord in childCollection.allRecords) {
      String childId = childRecord.childuid;
      String childFullName =
          "${childRecord.firstName ?? ''} ${childRecord.lastName ?? ''}".trim();
      String childFirstName = childRecord.firstName ?? '';
      String childLastName = childRecord.lastName ?? '';

      // Map full name, first name, and last name to childId
      keywordMap[childFullName] = {'id': childId, 'type': 'fullName'};
      keywordMap[childFirstName] = {'id': childId, 'type': 'firstName'};
      keywordMap[childLastName] = {'id': childId, 'type': 'lastName'};

      // Map ID to full name, first name, and last name
      idToKeywordMap[childId] = {
        'fullName': childFullName,
        'firstName': childFirstName,
        'lastName': childLastName,
      };
    }
  }

  @override
  void initState() {
    super.initState();
    prepareChildIdAndNameMap();
    messages.add(ChatMessage(
      user: aiUser,
      createdAt: DateTime.now(),
      text: "Hi! How can I help you today?",
    ));
  }

  Future<String> fetchChildrenDataOld() async {
    try {
      DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (parentSnapshot.exists) {
        Map<String, dynamic>? parentData =
            parentSnapshot.data() as Map<String, dynamic>?;
        if (parentData != null && parentData['children'] != null) {
          List<dynamic> childrenIDList = parentData['children'];
          Map<String, dynamic> childrenData = {};
          for (String childId in childrenIDList) {
            DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                .collection('children')
                .doc(childId)
                .get();

            if (childSnapshot.exists) {
              Map<String, dynamic>? childData =
                  childSnapshot.data() as Map<String, dynamic>?;
              if (childData != null &&
                  childData['data'] != null &&
                  childData['data']['selectedButtons'] != null &&
                  childData['data']['selectedFeelings'] != null) {
                List<dynamic> allFeelings = await decryptSelectedDataForChild(
                    childId, childData['data']['selectedFeelings']);
                for (int i = 0; i < allFeelings.length; i++) {
                  allFeelings[i]['timestamp'] =
                      allFeelings[i]['timestamp'].toDate();
                }
                List<dynamic> allButtons = await decryptSelectedDataForChild(
                    childId, childData['data']['selectedButtons']);
                for (int i = 0; i < allButtons.length; i++) {
                  allButtons[i]['timestamp'] =
                      allButtons[i]['timestamp'].toDate();
                }

                var stringFeelingList = allFeelings.join(", ");
                var stringButtonList = allButtons.join(", ");

                final childCollection = ChildCollectionWithKeys.instance;
                ChildRecord childRecord =
                    childCollection.getRecord(childId) as ChildRecord;
                childrenData[childId] = {
                  "first name": childRecord.firstName,
                  "last name": childRecord.lastName,
                  "username": childRecord.username,
                  "feelingsData": stringFeelingList,
                  "buttonsData": stringButtonList
                };
              } else {
                print("no data");
              }
            } else {
              print("don't work");
            }
          }
          return childrenData.toString();
        } else {
          print("no data");
          return "no data";
        }
      } else {
        print("don't work");
        return "don't work";
      }
    } catch (e) {
      print('Error fetching selected buttons: $e');
      return "error";
    }
  }

  Future<void> getAIResponse(ChatMessage m) async {
    // Process user message to replace keywords with IDs
    print('Processing user message${m.text}');
    String modifiedMessage = m.text;
    List<Map<String, String>> replacedKeywords = []; // Track replaced keywords

    keywordMap.forEach((keyword, details) {
      String lowerCaseKeyword = keyword.toLowerCase();
      String lowerCaseMessage = modifiedMessage.toLowerCase();

      if (lowerCaseMessage.contains(lowerCaseKeyword)) {
        String id = details['id']!;
        modifiedMessage = modifiedMessage.replaceAll(
            RegExp(RegExp.escape(keyword), caseSensitive: false), id);
        replacedKeywords.add({'id': id, 'type': details['type']!});
      }
    });

    // Calculate the date for 7 days ago
    DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

    setState(() {
      typingUsers.add(aiUser);
    });

    // Fetch data and get AI response
    String? childrenData =
        await fetchChildrenAnonDataforAI(filterDate: sevenDaysAgo);
    print('Message typed by user replaced with keywords: $modifiedMessage');

    String? response =
        await generateResponse(modifiedMessage, childrenData, context);
    print('Response by AI: $response');

    if (response != null) {
      // Replace IDs back with keywords
      String processedResponse = response;

      // Replace IDs that were in the replacedKeywords list
      replacedKeywords.forEach((replacement) {
        String id = replacement['id']!;
        String type = replacement['type']!;
        if (idToKeywordMap.containsKey(id)) {
          String keyword = idToKeywordMap[id]![type]!;
          processedResponse = processedResponse.replaceAll(id, keyword);
        }
      });

      // Find and replace IDs not in replacedKeywords
      idToKeywordMap.forEach((id, keywords) {
        if (!replacedKeywords.any((replacement) => replacement['id'] == id)) {
          // Use 'fullName' as default fallback keyword if present
          String fallbackKeyword = keywords['firstName'] ??
              keywords['fullName'] ??
              keywords['lastName'] ??
              id;
          processedResponse = processedResponse.replaceAll(id, fallbackKeyword);
        }
      });
      print('AI response changed: $processedResponse');

      setState(() {
        typingUsers.remove(aiUser);
        messages.insert(
            0,
            ChatMessage(
                user: aiUser,
                text: processedResponse,
                createdAt: DateTime.now()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSessionValid == false) {
      return SessionExpiredWidget(
        onLogout: () => logOutUser(context),
      );
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GradientText(
                'VoxiBot',
                gradient: LinearGradient(
                  colors: [Color(0xFFAC70F8), Color(0xFF7000FF)],
                ),
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Row(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Image.asset("assets/imgs/logo_without_text.png",
                      width: 60),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GradientText("Voxigo",
                      gradient: LinearGradient(colors: [
                        Colors.blue,
                        Colors.blueAccent,
                        Colors.deepPurpleAccent
                      ]),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                )
              ]),
            ],
          )),
      body: Column(
        children: [
          Expanded(
            child: DashChat(
              currentUser: user,
              onSend: (ChatMessage m) {
                // Insert user message and process it
                setState(() {
                  messages.insert(0, m);
                });
                getAIResponse(m); // Call AI processing
              },
              typingUsers: typingUsers,
              messages: messages,
              messageOptions: MessageOptions(
                timeFormat: DateFormat('HH:MM AA'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
