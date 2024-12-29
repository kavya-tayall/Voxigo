import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

class ColoringHome extends StatefulWidget {
  const ColoringHome({super.key});

  @override
  State<ColoringHome> createState() => _ColoringHomeState();
}

class _ColoringHomeState extends State<ColoringHome> {
  late ScribbleNotifier notifier;

  @override
  void initState() {
    notifier = ScribbleNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Center(child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.black,
                        width: 5,
                        style: BorderStyle.solid))),
            child: Padding(
                padding: EdgeInsets.only(bottom: 10, top: 10),
                child: Text(
                  "Coloring",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )),
          ),
        )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(style: BorderStyle.solid, color: Colors.black, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: (){notifier.clear();},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)
                    )
                  ),
                  child: Icon(Icons.clear),
                ),
                TextButton(
                  onPressed: (){notifier.undo();},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.undo),
                ),
                TextButton(
                  onPressed: (){notifier.redo();},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.redo),
                ),
                TextButton(
                  onPressed: (){notifier.setEraser();},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.cleaning_services),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.black);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.black),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.white);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square_outlined, color: Colors.black),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.red);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.red),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.orange);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.orange),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.yellow);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.yellow),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.green);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.green),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.blue);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.blue),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.purple);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.purple),
                ),
                TextButton(
                  onPressed: (){notifier.setColor(Colors.pink);},
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)
                      )
                  ),
                  child: Icon(Icons.square, color: Colors.pink),
                ),
            ]),
          ),
        ),
        body: Column(children: [
          Expanded(
            child: Scribble(notifier: notifier),
          ),

        ]));
  }
}
