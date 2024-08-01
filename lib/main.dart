import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'Buttons.dart';


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
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
List<FirstButton> buttons = [
   FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png', text: 'Button 1'),
   FirstButton(imagePath: 'assets/Screenshot 2024-07-29 at 4.31.43 PM.png', text: 'Button 2'),
   // Add more buttons as needed
 ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: <Widget>[
      Container(
          color: Colors.blueAccent,
          padding: EdgeInsets.all(8),
          child: HomeTopBar()),
      Expanded(
          child: Container(
              color: Colors.white, child: Center(child: Grid(buttons: buttons))))
    ]));
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
      crossAxisCount: 5,
      children: widget.buttons,
    );
  }
}

