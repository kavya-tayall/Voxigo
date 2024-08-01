import 'package:flutter/material.dart';



class CustomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.deepOrangeAccent,
      unselectedItemColor: Colors.orangeAccent,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_emotions),
          label: 'Feelings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.audiotrack),
          label: 'Music & Stories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
