import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'EditBar.dart';
import 'homePage.dart';
import 'Behaviour.dart';

//hi
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

  void addSelectedButton(FirstButton button) {
    _selectedButtons.add(button);
    notifyListeners();
  }

  void clearSelectedButtons(){
    _selectedButtons.clear();
    notifyListeners();
  }

  List getSelectedButtons(){
    return this._selectedButtons;
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
  final List<FirstButton> buttons;
  const Grid({Key? key, required this.buttons}) : super(key: key);

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 7,
      physics: NeverScrollableScrollPhysics(), // Disable scrolling
      shrinkWrap: true,
      children: widget.buttons, // Make the GridView wrap its content
    );
  }
}
