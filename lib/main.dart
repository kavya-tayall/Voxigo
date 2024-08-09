import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
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
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}


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
  List<dynamic> _pathOfBoard = ["buttons"];
  List<dynamic> get pathOfBoard => _pathOfBoard;

  final Function(FirstButton) onButtonPressed;
  final Map <String, dynamic> data;

  Grid({required this.data, required this.onButtonPressed});

  @override
  State<Grid> createState() => _GridState();
}

class _GridState extends State<Grid> {
  dynamic visibleButtons = [];

  @override
  void initState() {
    super.initState();
    // Set initial visible buttons
    updateVisibleButtons();
  }

  void updateVisibleButtons() {
    setState(() {
      dynamic buttons = widget.data;
      for (var folder in widget.pathOfBoard) {
        buttons = buttons[folder];
      }
      visibleButtons = buttons;

    });
  }

  void _updateGridPath(int folderPath, String folderPath2){
    setState(() {
      widget.pathOfBoard.add(folderPath);
      widget.pathOfBoard.add(folderPath2);
      print("done");
      updateVisibleButtons();
    });
  }

  void goBack(){
    setState(() {
      if (widget.pathOfBoard.length >1){
        widget.pathOfBoard.removeLast();
        widget.pathOfBoard.removeLast();
        updateVisibleButtons();
      }
    });
  }

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
                size: buttonSize,
                onPressed: () {
                  // Call the onButtonPressed callback with a new FirstButton
                  widget.onButtonPressed(
                      FirstButton(
                    imagePath: visibleButtons[index]["image_url"],
                    text: visibleButtons[index]["label"],
                    size: buttonSize,
                    onPressed: () {},
                  ));
                },
              );
            } else {
              return FolderButton(
                imagePath: visibleButtons[index]["image_url"],
                text: visibleButtons[index]["label"],
                ind: index,
                size: buttonSize,
                onPressed: () => _updateGridPath(index, "buttons"),
                // Pass the size parameter
              );
            }
          },
        );
      },
    );
  }
}
