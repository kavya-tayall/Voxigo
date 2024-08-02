import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'main.dart';


class EditBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(30),
              ),
              onPressed: () {
                print("add");
              },
              child: Icon(Icons.add),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(30),
              ),
              onPressed: () {
                print("edit");
              },
              child: Icon(Icons.edit),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(30),
              ),
              onPressed: () {
                print("move");
              },
              child: Icon(Icons.open_with),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(30),
              ),
              onPressed: () {
                print("remove");
              },
              child: Icon(Icons.delete),
            ),
          ],
      ),
    );
  }
}
