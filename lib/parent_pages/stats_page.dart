import 'package:flutter/material.dart';
import '../widgets/buttons_table.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
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
              Tab(text: 'Search View'),
              Tab(text: 'AI View'),
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
                Expanded(
                  child: ButtonsTable(searchText: searchText),
                ),
              ],
            ),

            Center(child: Text('AI View coming soon')),
          ],
        ),
      ),
    );
  }
}