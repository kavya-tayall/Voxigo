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
    ThemeData theme = Theme.of(context);

    return BottomNavigationBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: theme.disabledColor,
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: theme.iconTheme.color),
          label: 'Home',
        ),
        if (Provider.of<ChildProvider>(context, listen: false)
                .childPermission
                ?.emotionHandling ==
            true)
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions,color: theme.iconTheme.color),
            label: 'Feelings',
          ),
        if (Provider.of<ChildProvider>(context, listen: false)
                .childPermission
                ?.audioPage ==
            true)
          BottomNavigationBarItem(
            icon: Icon(Icons.audiotrack,color: theme.iconTheme.color),
            label: 'Music & Stories',
          ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings,color: theme.iconTheme.color),
          label: 'Settings',
        ),
      ],
    );
  }
}
