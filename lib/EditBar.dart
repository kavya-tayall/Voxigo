import 'package:flutter/material.dart';


class EditBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AddButton(),
            MoveButton(),
            EditButton(),
            RemoveButton(),
          ],
      );
  }
}

class AddButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
  return ElevatedButton(
  style: ElevatedButton.styleFrom(
  shape: CircleBorder(),
  padding: EdgeInsets.all(30),

  ),
  onPressed: () {
  print("add");
  },
  child: Icon(Icons.add),
  );
  }
}

class MoveButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        print("move");
      },
      child: Icon(Icons.open_with),
    );
  }
}

class EditButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        print("edit");
      },
      child: Icon(Icons.edit),
    );
  }
}

class RemoveButton extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),

      ),
      onPressed: () {
        print("remove");
      },
      child: Icon(Icons.delete),
    );
  }
}