import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class FeelingsStatsPage extends StatefulWidget {
  @override
  _FeelingsStatsPageState createState() => _FeelingsStatsPageState();
}

class _FeelingsStatsPageState extends State<FeelingsStatsPage> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: TabBar(
            tabs: [
              Tab(text: 'Timeline View'),
              Tab(text: 'Info View'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Placeholder(),
              ],
            ),

            Center(child: Text('Info view')),
          ],
        ),
      ),
    );
  }
}