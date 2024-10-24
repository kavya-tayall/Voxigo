import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/widgets/child_provider.dart';


class FeelingsButton extends StatelessWidget {
  final String feeling;
  final String imagePath;
  final List suggestions;

  const FeelingsButton({
    Key? key,
    required this.feeling,
    required this.imagePath,
    required this.suggestions,
  }) : super(key: key);

  Color _getButtonColor() {
    switch (feeling) {
      case "Happy":
        return Color(0xFF128E00);
      case "Sad":
        return Colors.blue[300]!;
      case "Angry":
        return Colors.red[600]!;
      case "Nervous":
        return Color(0xFF80008E);
      case "Bored":
        return Color(0xFF636363);
      case "Tired":
        return Color(0xFFC86B00);
      default:
        return Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Provider.of<ChildProvider>(context, listen: false)
            .addSelectedFeelings(feeling, Timestamp.now());
        Navigator.pushNamed(context, '/suggestions', arguments: suggestions);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: _getButtonColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(3, 3),
            )
          ],
        ),
        constraints: BoxConstraints(
          minWidth: 200,
          minHeight: 220,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              height: 150,
            ),
            const SizedBox(height: 16),
            Text(
              feeling,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
