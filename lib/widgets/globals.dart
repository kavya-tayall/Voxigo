import 'package:flutter/material.dart';
import 'package:test_app/main.dart'; // Ensure this points to the file containing BasePage

final GlobalKey<BasePageState> basePageKey = GlobalKey<BasePageState>();
bool atBasePage = true;

Future<String?> showButtonOrFolderTextInputDialog(
    BuildContext context, String hintText) async {
  TextEditingController controller = TextEditingController();
  final theme = Theme.of(context);

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        titleTextStyle: theme.textTheme.headlineSmall, // Apply title text style
        contentTextStyle:
            theme.textTheme.bodyMedium, // Apply content text style
        title: Text(
          hintText,
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter your input here",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.secondary),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Submit'),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );
}
