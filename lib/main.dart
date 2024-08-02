import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'EditBar.dart';
import 'homePage.dart';
import 'Behaviour.dart';


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
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {

  List<FirstButton> _selectedButtons = [];
  List<FirstButton> get selectedButtons => _selectedButtons;

  List <Map> _visibleButtons = [];
  List<Map> get visibleButtons => _visibleButtons;

  List <String> _pathOfBoard = [];
  List<String> get pathOfBoard => _pathOfBoard;

  void addSelectedButton(FirstButton button) {
    _selectedButtons.add(button);
    notifyListeners();
  }

  void clearSelectedButtons(){
    _selectedButtons.clear();
    notifyListeners();
  }

  List getSelectedButtons(){
    return _selectedButtons;
  }

  void updateGrid(List newButtons){
    _visibleButtons = [for (var item in newButtons) item];
  }

  void updateGridPath(String folderPath){
    _pathOfBoard.add(folderPath);
  }

  List getVisibleButtons(){
    return _visibleButtons;
  }

  List getPath(){
    return _pathOfBoard;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

class Grid extends StatefulWidget {
  const Grid({super.key});

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  Map <String, dynamic> _data = {};

  @override
  void initState(){
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async{
    final jsonString = await rootBundle.loadString("assets/board_info/board.json");
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _data = jsonData;
      context.read()<MyAppState>().updateGrid([for (var info in _data["buttons"]) info]) ;
    });
  }




  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      physics: NeverScrollableScrollPhysics(), // Disable scrolling
        shrinkWrap: true,
        itemCount: context.watch<MyAppState>().visibleButtons.length,
        itemBuilder: (BuildContext context, int index){
        print("asdf");
        if (context.watch<MyAppState>().visibleButtons[index]["folder"] == false){
          return FirstButton(imagePath: context.watch<MyAppState>().visibleButtons[index]["image_url"], text: context.watch<MyAppState>().visibleButtons[index]["label"]);
        } else{
          return FolderButton(imagePath: context.watch<MyAppState>().visibleButtons[index]["image_url"], text: context.watch<MyAppState>().visibleButtons[index]["label"]);
        }
      }
    );
  }
}
