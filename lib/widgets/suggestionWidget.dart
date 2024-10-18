import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/ai_utility.dart';
import 'package:gradient_borders/gradient_borders.dart';

class AISuggestionDialog extends StatefulWidget {
  String currentPhrase;

  AISuggestionDialog({required this.currentPhrase});

  @override
  State<AISuggestionDialog> createState() => _AISuggestionDialogState();
}

class _AISuggestionDialogState extends State<AISuggestionDialog> {
  dynamic pictogramsData;
  List<dynamic> suggestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPictograms();
    _loadSuggestions();
  }

  Future<void> _loadPictograms() async {
    String jsonString =
        await rootBundle.loadString('assets/board_info/pictograms.json');
    setState(() {
      pictogramsData = jsonDecode(jsonString);
      _checkLoading();
    });
  }

  Future<void> _loadSuggestions() async {
    String? suggestionString =
        await generateSentenceSuggestion(widget.currentPhrase, context);
    setState(() {
      suggestions = jsonDecode(suggestionString!);
      _checkLoading();
    });
  }

  void _checkLoading() {
    // If both pictogram data and suggestions are loaded, stop showing the spinner
    if (pictogramsData != null && suggestions.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      // To allow full custom border visibility
      contentPadding: EdgeInsets.zero,
      // Remove padding around content
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      content: Container(
        decoration: BoxDecoration(
          border: GradientBoxBorder(
            gradient:
                LinearGradient(colors: [Color(0xFFAC70F8), Color(0xFFFF79FD)]),
            width: 4,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.white, // Background color inside the border
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding inside the border
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              minHeight: 300,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      return AISuggestion(
                        phrase: suggestions[index],
                        pictogramsData: pictogramsData,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

// title widget need to put in
/*
Text(
        "Sentence Suggestions",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
 */

class AISuggestion extends StatelessWidget {
  final String phrase;
  final dynamic pictogramsData;

  AISuggestion({required this.phrase, required this.pictogramsData});

  @override
  Widget build(BuildContext context) {
    List<String> words = phrase.split(' ');

    return Column(children: [
      SizedBox(
        height: 100, // Set a fixed height or adjust as per your needs
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: words.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  // For each word, display a column with the matching pictogram
                  return PhraseColumn(
                    word: words[index],
                    pictogramsData: pictogramsData,
                  );
                },
              ),
            ),
            SizedBox(
                width: 40,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.lightBlue,
                    minimumSize: Size(40, 40),
                  ),
                  onPressed: () {},
                  child: Center(
                    child: Icon(Icons.check),
                  ),
                ))
          ],
        ),
      ),
      Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
        child: Divider(
          thickness: 2,
          color: Colors.grey,
        ),
      )
    ]);
  }
}

class PhraseColumn extends StatefulWidget {
  final List pictogramsData;
  final String word;

  PhraseColumn({
    required this.pictogramsData,
    required this.word,
  });

  @override
  State<PhraseColumn> createState() => _PhraseColumnState();
}

class _PhraseColumnState extends State<PhraseColumn> {
  late Image image;

  @override
  void initState() {
    image = searchButtonData(widget.pictogramsData, widget.word);
  }

  Image searchButtonData(List<dynamic> data, String keyword) {
    keyword = keyword.trim().toLowerCase();
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            return Image.network(
              "https://static.arasaac.org/pictograms/${item['_id']}/${item['_id']}_2500.png",
              width: 60,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Image.asset("assets/imgs/angry.png", width: 60);
              },
            );
          }
        }
      }
    }
    return Image.asset("assets/imgs/angry.png");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
      child: Column(children: [
        image,
        Text(widget.word,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20))
      ]),
    );
  }
}
