import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/ai_utility.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

import '../widgets/child_provider.dart';

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
    firstName: 'MindAI',
  );

  List<ChatMessage> messages = <ChatMessage>[];
  List<ChatUser> typingUsers = []; // Maintain typing users

  @override
  void initState() {
    super.initState();
    messages.add(ChatMessage(
      user: user,
      createdAt: DateTime.now(),
      text: "hello",
    ));
  }


  Future<String> fetchChildrenData() async {
    try {
      DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (parentSnapshot.exists) {
        Map<String, dynamic>? parentData = parentSnapshot.data() as Map<String, dynamic>?;
        if (parentData != null && parentData['children'] != null) {
          List<dynamic> childrenIDList = parentData['children'];
          Map<String, dynamic> childrenData = {};
          for (String childId in childrenIDList){
            DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                .collection('children')
                .doc(childId)
                .get();

            if (childSnapshot.exists) {
              Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
              if (childData != null &&
                  childData['data'] != null &&
                  childData['data']['selectedButtons'] != null &&
                  childData['data']['selectedFeelings'] != null) {
                List<dynamic> allFeelings = childData['data']['selectedFeelings'];
                for (int i = 0; i < allFeelings.length; i++) {
                  allFeelings[i]['timestamp'] = allFeelings[i]['timestamp'].toDate();
                }
                List<dynamic> allButtons = childData['data']['selectedButtons'];
                for (int i = 0; i < allButtons.length; i++) {
                  allButtons[i]['timestamp'] = allButtons[i]['timestamp'].toDate();
                }

                var stringFeelingList = allFeelings.join(", ");
                var stringButtonList = allButtons.join(", ");

                childrenData[childId] = {"first name": childData['first name'], "last name": childData['last name'], "username": childData['username'], "feelingsData": stringFeelingList, "buttonsData": stringButtonList};

              } else {
                print("no data");
              }
            } else{
              print("dont work");
            }
          }
          return childrenData.toString();


        } else {
          print("no data");
          return "no data";
        }
      } else{
        print("dont work");
        return ("dont work");
      }


    } catch (e) {
      print('Error fetching selected buttons: $e');
      return "error";
    }
  }




  Future<void> getAIResponse(ChatMessage m) async {
    setState(() {
      typingUsers.add(aiUser);
    });
    String? childrenData = await fetchChildrenData();
    String? response = await generateResponse(m.text, childrenData, context);

    if (response != null) {
      setState(() {
        typingUsers.remove(aiUser); // Remove AI from typing
        messages.insert(0, ChatMessage(
          user: aiUser,
          text: response,
          createdAt: DateTime.now(),
        ));
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashChat(
        currentUser: user,
        onSend: (ChatMessage m) {
          setState(() {
            messages.insert(0, m);
          });
          getAIResponse(m);
        },
        typingUsers: typingUsers, // Pass the typing users list
        messages: messages,
      ),
    );
  }
}
