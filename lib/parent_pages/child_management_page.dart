import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/parent_music_page.dart';
import 'edit_child_grid.dart';

class GradientText extends StatelessWidget {
  const GradientText(
      this.text, {
        required this.gradient,
        this.style,
      });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class ChildManagementPage extends StatefulWidget {
  final Function(int) onNavigate; // Callback to update index

  ChildManagementPage({required this.onNavigate}); // Pass the callback

  @override
  _ChildManagementPageState createState() => _ChildManagementPageState();
}

class _ChildManagementPageState extends State<ChildManagementPage> {

  Map<String, String> childIdToUsername = {};
  bool isLoading = true;
  String adminName = "";

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }

  Future<void> fetchChildren() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String parentId = currentUser.uid;
        DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .get();

        if (parentSnapshot.exists) {
          Map<String, dynamic>? parentData =
          parentSnapshot.data() as Map<String, dynamic>?;
          print(parentData);
          adminName = parentData?['name'];
          if (parentData != null && parentData['children'] != null) {
            List<String> childIds = List<String>.from(parentData['children']);

            for (String childId in childIds) {
              DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                  .collection('children')
                  .doc(childId)
                  .get();

              if (childSnapshot.exists) {
                Map<String, dynamic>? childData =
                childSnapshot.data() as Map<String, dynamic>?;
                if (childData != null && childData['username'] != null) {
                  setState(() {
                    childIdToUsername[childId] = childData['username'];
                  });
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching children: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffdde8ff),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75.0),
        child: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.home, color: Colors.black, size: 30),
              Row(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Image.asset("assets/imgs/logo_without_text.png",
                      width: 60),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GradientText("MindBridge",
                      gradient: LinearGradient(colors: [
                        Colors.blue,
                        Colors.blueAccent,
                        Colors.deepPurpleAccent
                      ]),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 30)),
                )
              ]),
            ],
          ),
          toolbarHeight: 80,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello $adminName! 👋",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.black),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Quick Actions ⚡️',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 25),
                ),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 4),
                      onPressed: () {
                        widget.onNavigate(2);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF64CD3),
                              Color(0xFFAF70FF)
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Container(
                          width: 150,
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.chat,
                                  size: 75, color: Color(0xA6000000)),
                              Text(
                                "Chat with MindAI",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xA6000000),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 4),
                      onPressed: () {
                        setState(() {
                          widget.onNavigate(1);
                        });
                      },
                      child: Container(
                        width: 150,
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart,
                                size: 75, color: Color(0xA6000000)),
                            Text(
                              "Button & Feeling Stats",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xA6000000),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  ]),
              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Manage Your Children 👥',
                          style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: childIdToUsername.entries.map((entry) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 16.0, left: 6, right: 6),
                            decoration: BoxDecoration(
                              color: Color(0xffececec),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              title: Text(entry.value),
                              children: <Widget>[
                                ListTile(
                                  title: Text('Edit Grid'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChildGridPage(username: entry.value),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: Text('Edit Music'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ParentMusicPage(
                                            username: entry.value),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: Text('Edit Username/Password'),
                                  onTap: () {
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ]
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}