import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'homePage.dart';
import 'Behaviour.dart';

typedef VoidCallBack = void Function();


void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: BasePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}


class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int selectedIndex = 0;


  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
      case 1:
        page = Placeholder();
      case 2:
        page = Placeholder();
      case 3:
        page = BehaviourPage();
      case 4:
        page = Placeholder();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }


    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: page),
          CustomNavigationBar(
            selectedIndex: selectedIndex,
            onItemTapped: onItemTapped,
          ),
        ],
      ),
    );
  }
}