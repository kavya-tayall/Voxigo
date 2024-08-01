import 'package:flutter/material.dart';
import 'homepage_top_bar.dart';


class FirstButton extends StatelessWidget {
  final String imagePath;
  final String text;

  const FirstButton({Key? key, required this.imagePath, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,  // Set the width of the button
      height: 100, // Set the height of the button
      child: ElevatedButton(
        onPressed: () {
          // You can access the passed parameters here
          print(text);

        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Ensure no rounding to keep it square
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch content horizontally
          children: <Widget>[
            Expanded(
              child: Image.asset(
                imagePath, // Use the passed image path
                width: 50.0,
                height: 20.0,
                fit: BoxFit.cover, // Ensure the image covers the button
              ),
            ),
            Text(
              text, // Use the passed text
              textAlign: TextAlign.center, // Center text horizontally
            ),
          ],
        ),
      ),
    );
  }
}
