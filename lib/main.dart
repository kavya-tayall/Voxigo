import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:test_app/parent_pages/child_management_page.dart';
import 'package:test_app/parent_pages/stats_page.dart';
import 'child_pages/music_page.dart';
import 'widgets/child_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'child_pages/home_page.dart';
import 'child_pages/settings_page.dart';
import 'parent_pages/parent_login_page.dart';
import 'child_pages/child_login_page.dart';
import 'parent_pages/parent_settings.dart';
import 'child_pages/feelings_page.dart';
import 'child_pages/fidget_spinner_suggestion.dart';
import 'child_pages/suggestions_page.dart';
import 'child_pages/coloring_suggestion.dart';
import 'child_pages/breathing_suggestion.dart';
import 'child_pages/54321_suggestion.dart';

typedef VoidCallBack = void Function();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChildProvider(),
      child: MyApp(),
    ),
  );
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
          '/base': (_) => BasePage(),
          '/feelings': (_) => FeelingsPage(),
          '/music': (_) => MusicPage(),
          '/suggestions': (_) => SuggestionsPage(),
          '/fidget': (_) => FidgetSpinnerHome(),
          '/coloring': (_) => ColoringHome(),
          '/breathing': (_) => BreathingHome(),
          '/54321': (_) => FiveCalmDownHome(),
          '/parent_base': (_) => ParentBasePage(),
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

    final assetJsonString = await rootBundle.loadString("assets/board_info/board.json");

    await file.writeAsString(assetJsonString);

    final jsonData = jsonDecode(assetJsonString);

    setState(() {
      data = Map.from(jsonData);
      isLoading = false;
    });
  }


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

        updatePathOfBoard(pathOfBoard);
      }
    });
  }


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
        page = FeelingsPage();
      case 2:
        page = MusicPage();
      case 3:
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

class ParentBasePage extends StatefulWidget {
  const ParentBasePage({super.key});

  @override
  _ParentBasePageState createState() => _ParentBasePageState();
}

class _ParentBasePageState extends State<ParentBasePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    ChildManagementPage(),
    StatsPage(),
    ParentSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard'),
      ),
      body: Center(

        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Child Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
