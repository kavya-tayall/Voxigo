import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'bottom_nav_bar.dart';
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
  State<BasePage> createState() => BasePageState();
}

class BasePageState extends State<BasePage> {
  int selectedIndex = 0;
  List<dynamic> pathOfBoard = ["buttons"];
  Map<String, List> data = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _loadJsonData() async {
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/board.json';

    // Check if the file exists
    File file = File(filePath);
    if (await file.exists()) {
      // Read from file if it exists
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);
      setState(() {
        data = Map.from(jsonData);
        isLoading = false; // Data loading complete
      });
    } else {
      // If the file doesn't exist, load from assets
      final assetJsonString = await rootBundle.loadString("assets/board_info/board.json");
      await file.writeAsString(assetJsonString); // Copy asset to file
      final jsonData = jsonDecode(assetJsonString);
      setState(() {
        data = Map.from(jsonData);
        isLoading = false; // Data loading complete
      });
    }
  }


  // Update the path of the board
  void updatePathOfBoard(List<dynamic> newPath) {
    setState(() {
      pathOfBoard = List.from(newPath);
    });
  }

  void goBack(){
    setState(() {
      if (pathOfBoard.length > 1) {
        pathOfBoard.removeLast();
        pathOfBoard.removeLast();

        updatePathOfBoard(pathOfBoard); // Notify that path has changed
      }
    });
  }

  // Modify the data (you can customize this based on your app's logic)
  void modifyData(Map<String, List> newData) {
    setState(() {
      data = Map.from(newData);
    });
  }


  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = DataWidget(
            data: data,
            onDataChange: modifyData,
            child: HomePage());
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