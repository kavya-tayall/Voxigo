import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
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

  Map _allButtons = {};
  Map get allButtons => _allButtons;

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
    notifyListeners();
  }

  void updateGridPath(String folderPath){
    _pathOfBoard.add(folderPath);
    notifyListeners();
  }

  void loadData(Map data){
    _allButtons = Map.from(data);
    updateGrid(_allButtons["buttons"]);
  }

  void goBack(){
    _pathOfBoard.removeLast();
    _pathOfBoard.removeLast();
    dynamic temp = _allButtons["buttons"];
    for (var i=0; i<_pathOfBoard.length;i++){
      temp = _allButtons[_pathOfBoard[i]];
    }
    updateGrid(temp);
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  Map <String, dynamic> _data = {};

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState(){
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async{
    final jsonString = await rootBundle.loadString("assets/board_info/board.json");
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _data = Map.from(jsonData);
      context.read<MyAppState>().loadData(_data);
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

class Grid extends StatelessWidget {
  final List<Map> visibleButtons;
  final List<String> pathOfBoard;

  Grid({required this.visibleButtons, required this.pathOfBoard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 7; // Fixed number of columns
        int fixedRows = 5; // Fixed number of rows


        double availableHeight = constraints.maxHeight;

        // Calculate maximum number of items that can fit based on number of rows
        int maxItems = 35;
        double buttonSize = ((availableHeight - 50) / fixedRows);



        // Limit the number of items shown to the maximum number that fits in the grid
        int visibleItemCount = visibleButtons.length > maxItems ? maxItems : visibleButtons.length;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          physics: NeverScrollableScrollPhysics(), // Disable scrolling
          shrinkWrap: true,
          itemCount: visibleItemCount,
          itemBuilder: (BuildContext context, int index) {
            if (visibleButtons[index]["folder"] == false) {
              return FirstButton(
                imagePath: visibleButtons[index]["image_url"],
                text: visibleButtons[index]["label"],
                size: buttonSize, // Pass the size parameter
              );
            } else {
              return FolderButton(
                imagePath: visibleButtons[index]["image_url"],
                text: visibleButtons[index]["label"],
                ind: index,
                btns: visibleButtons,
                size: buttonSize, // Pass the size parameter
              );
            }
          },
        );
      },
    );
  }
}
