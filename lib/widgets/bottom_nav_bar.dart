import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'child_provider.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        if (Provider.of<ChildProvider>(context, listen: false)
                .childData?['settings']['emotion handling'] ==
            true)
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions),
            label: 'Feelings',
          ),
        if (Provider.of<ChildProvider>(context, listen: false)
                .childData?['settings']['audio page'] ==
            true)
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
