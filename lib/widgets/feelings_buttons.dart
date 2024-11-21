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
        return const Color(0xFF43A047); // Green accent
      case "Sad":
        return const Color(0xFF2196F3); // Blue
      case "Angry":
        return const Color(0xFFD32F2F); // Red accent
      case "Nervous":
        return const Color(0xFF8E24AA); // Purple accent
      case "Bored":
        return const Color(0xFF757575); // Grey
      case "Tired":
        return const Color(0xFFFFA000); // Amber
      default:
        return Colors.grey[300]!; // Light grey for default
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
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 3,
              blurRadius: 6,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              spreadRadius: -2,
              blurRadius: 3,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 200,
          minHeight: 240,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePath,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              feeling,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}