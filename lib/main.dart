import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'child_pages/MusicStories.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'child_pages/home_page.dart';
import 'child_pages/behavior_page.dart';
import 'child_pages/settings_page.dart';
import 'parent_pages/parent_login_page.dart';
import 'child_pages/child_login_page.dart';
import 'parent_pages/parent_settings.dart';

typedef VoidCallBack = void Function();


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        ),
        initialRoute: '/parent_login',
        routes: {
          '/parent_login': (_) => ParentLoginPage(),
          '/child_login': (_) => ChildLoginPage(),
          '/base': (_) => BasePage()
        },
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadJsonData();
    });
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
  Future<void> _loadJsonData() async {
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/board.json';

    File file = File(filePath);

    // Check if the file exists in the documents directory
    if (await file.exists()) {
      // Load the data from the file if it exists
      String fileContents = await file.readAsString();
      final jsonData = jsonDecode(fileContents);
      setState(() {
        data = Map.from(jsonData);
        isLoading = false; // Data loading complete
      });
    } else {
      // If the file doesn't exist, copy it from the assets
      final assetJsonString = await rootBundle.loadString("assets/board_info/board.json");
      await file.writeAsString(assetJsonString); // Copy asset to file

      // Parse JSON data
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
            child: PathWidget(
                onPathChange: updatePathOfBoard,
                pathOfBoard: pathOfBoard,
                child: HomePage()));
      case 1:
        page = Placeholder();
      case 2:
        page = MusicStoriesPage();
      case 3:
        page = BehaviourPage();
      case 4:
        page = CustomSettings();
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

class ParentBasePage extends StatelessWidget {
  const ParentBasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ParentHomePage();
  }
}
