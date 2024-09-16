import 'package:flutter/material.dart';


Map<String, String> temp = {"Fidget Spinner": "/fidget", "PlaceHolder": "/feelings", "Coloring": "/coloring"};

class SuggestionsPage extends StatelessWidget {
  const SuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Center(
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 5, style: BorderStyle.solid))),
                child: Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 10), child: Text("Suggestions", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
              ),
            )),
        body: ListView.builder(
          itemCount: temp.length,
          itemBuilder: (BuildContext context, int index) {
            final suggestion = temp.keys.toList()[index];
            const imagePath = "asdf";
            final route = temp.values.toList()[index];

            return SuggestionTile(suggestion: suggestion, imagePath: imagePath, route: route,);

          },
        ));
  }
}


class SuggestionTile extends StatelessWidget {
  final String suggestion;
  final String imagePath;
  final String route;


  const SuggestionTile({
    Key? key,
    required this.suggestion,
    required this.imagePath,
    required this.route
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 125,
        child: ElevatedButton(
            onPressed: () {Navigator.pushNamed(context, route);},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 3.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              ),
            ),
            child: Text(suggestion, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 50))),
      ),
    );
  }
}


