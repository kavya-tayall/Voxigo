import 'package:flutter/material.dart';
import 'buttons_stats_page.dart';

class StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ButtonsStatsPage()),
            );
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                Icons.bar_chart,
                size: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
