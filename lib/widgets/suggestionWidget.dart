import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'buttons.dart';

class AISuggestion extends StatefulWidget {
  final String phrase;

  AISuggestion({required this.phrase});

  @override
  _AISuggestionState createState() => _AISuggestionState();
}

class _AISuggestionState extends State<AISuggestion> {
  List<dynamic> pictogramsData = [];

  @override
  void initState() {
    super.initState();
    _loadPictograms();
  }

  Future<void> _loadPictograms() async {
    String jsonString = await rootBundle.loadString('assets/board_info/pictograms.json');
    setState(() {
      pictogramsData = jsonDecode(jsonString);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Split the phrase into individual words
    List<String> words = widget.phrase.split(' ');

    return ListView.builder(
      itemCount: words.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        // For each word, display a column with the matching pictogram
        return PhraseColumn(
          word: words[index],
          pictogramsData: pictogramsData,
        );
      },
    );
  }
}

class PhraseColumn extends StatelessWidget {
  final List pictogramsData;
  final String word;

  PhraseColumn({
    required this.pictogramsData,
    required this.word,
  });

  dynamic searchButtonData(List<dynamic> data, String keyword) {
    print(keyword);
    keyword = keyword.trim().toLowerCase();
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            return item;
          }
        }
      }
    }
    return null;
  }

  Future<FirstButton> createFirstButtonFromData(Map<String, dynamic>? data, String enteredText) async {
    if (data == null) {
      return FirstButton(
        id: 'not_found',
        imagePath: 'not_found.png',
        text: enteredText,
        size: 60.0,
        onPressed: () {},
      );
    }

    String imageUrl = "https://static.arasaac.org/pictograms/${data['_id']}/${data['_id']}_2500.png";
    return FirstButton(
      id: data["_id"].toString(),
      imagePath: imageUrl.split('/').last,
      text: enteredText,
      size: 60.0,
      onPressed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    var data = searchButtonData(pictogramsData, word);

    return FutureBuilder<FirstButton>(
      future: createFirstButtonFromData(data, word),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return Row(
              children: [snapshot.data!],
            );
          } else {
            return Text('Error loading button');
          }
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}