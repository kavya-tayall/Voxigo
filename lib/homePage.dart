import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'EditBar.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var selectedButtons = context.watch<MyAppState>().selectedButtons;
    var visibleButtonsVar = context.watch<MyAppState>().visibleButtons;
    var pathOfBoardVar = context.watch<MyAppState>().pathOfBoard;


    return Column(children: <Widget>[
      Container(
        height: 130,
        color: Colors.blueAccent,
        padding: EdgeInsets.all(8),
        child: HomeTopBar(clickedButtons: selectedButtons)),
      Container(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          height: 50,
          child: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  Visibility(
                    visible: true,
                    child: TextButton.icon(icon: Icon(Icons.arrow_back_rounded),
                      onPressed: () {context.read<MyAppState>().goBack();},
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero, // Make the corners sharp
                        ),
                      ),),
                  ),
                  Container(
                    width: 2,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: TextButton.icon(icon: Icon(Icons.clear),
                      onPressed: () {context.read<MyAppState>().clearSelectedButtons();},
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero, // Make the corners sharp
                        ),
                      ),),
                  ),
                  Container(
                    width: 2,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: TextButton.icon(icon: Icon(Icons.play_arrow), onPressed: () => {},
                      label: const Text('Play'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero, // Make the corners sharp
                        ),
                      ),),
                  ),
                  Container(
                    width: 2,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: TextButton.icon(icon: Icon(Icons.auto_mode), onPressed: () => {},
                      label: const Text('Helper'),
                      style: TextButton.styleFrom(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.zero, // Make the corners sharp
                        ),
                      ),
                    ),
                  ),
                ]
            ),
          ),
        )
      ),
      Expanded(
          child: Container(
              color: Colors.transparent,
              child: Center(child: Grid(visibleButtons: visibleButtonsVar, pathOfBoard: pathOfBoardVar)))),
      EditBar(),
      SizedBox(height: 20),
    ]);
  }
}
