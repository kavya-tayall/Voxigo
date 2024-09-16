import 'package:flutter/material.dart';
import 'package:test_app/child_pages/suggestions_page.dart';

class FeelingsButton extends StatelessWidget {
  final String feeling;
  final String imagePath;
  final List suggestions;


  const FeelingsButton({
    Key? key,
    required this.feeling,
    required this.imagePath,
    required this.suggestions
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
      onPressed: () {Navigator.pushNamed(context, '/suggestions');},
      child: Column(
        children: [
          Image.asset(imagePath, width: MediaQuery.sizeOf(context).width/7,),
          Text(
            feeling,
            style: TextStyle(
              backgroundColor: Colors.transparent,
              color: Colors.black,
              fontSize: 20
            ),
          )
        ]
      )
    );
  }
}
