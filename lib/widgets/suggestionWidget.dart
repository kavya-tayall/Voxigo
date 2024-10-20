import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/ai_utility.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:test_app/main.dart';

import '../child_pages/home_page.dart';

class AISuggestionDialog extends StatefulWidget {
  String currentPhrase;
  final GlobalKey<HomePageState> homePageKey;

  AISuggestionDialog({required this.currentPhrase, required this.homePageKey});

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
                        homePageKey: widget.homePageKey, // Pass it here
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


class AISuggestion extends StatefulWidget {
  final String phrase;
  final dynamic pictogramsData;
  final GlobalKey<HomePageState> homePageKey; // Add this line

  AISuggestion({required this.phrase, required this.pictogramsData, required this.homePageKey});

  @override
  State<AISuggestion> createState() => _AISuggestionState();
}

class _AISuggestionState extends State<AISuggestion> {
  FlutterTts flutterTts = FlutterTts();
  List<String> imageUrls = [];


  @override
  Widget build(BuildContext context) {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    List<String> words = widget.phrase.split(' ');

    return Column(children: [
      SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: words.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return PhraseColumn(
                    word: words[index],
                    pictogramsData: widget.pictogramsData,
                    onImageAdded: (imageUrl) {
                      // Update the imageUrls list when an image is added
                      setState(() {
                        imageUrls.add(imageUrl);
                      });
                    },
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
                  onPressed: () async {
                    await flutterTts.speak(widget.phrase);
                  },
                  child: Center(
                    child: Icon(Icons.play_arrow_sharp),
                  ),
                )),
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
                  onPressed: () {
                    final homePageState = widget.homePageKey.currentState;
                    if (homePageState != null) {
                      homePageState.addPhraseToTopBar(widget.phrase, imageUrls);
                      print("Phrase added to top bar.");
                    } else {
                      print("HomePageState not found!");
                    }
                    Navigator.of(context).pop(); // Close the dialog
                  },
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
  final List<dynamic> pictogramsData;
  final String word;
  final Function(String) onImageAdded;

  PhraseColumn({
    required this.pictogramsData,
    required this.word,
    required this.onImageAdded,
  });

  @override
  State<PhraseColumn> createState() => _PhraseColumnState();
}

class _PhraseColumnState extends State<PhraseColumn> {
  late String imageUrl;
  bool imageLoaded = false; // To track if the image has been loaded

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    String fetchedImageUrl = await searchButtonData(widget.pictogramsData, widget.word);
    setState(() {
      imageUrl = fetchedImageUrl;
      imageLoaded = true; // Mark image as loaded
    });
    widget.onImageAdded(imageUrl); // Call the callback only after image is loaded
  }

  Future<String> searchButtonData(List<dynamic> data, String keyword) async {
    keyword = keyword.trim().toLowerCase();
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            return "https://static.arasaac.org/pictograms/${item['_id']}/${item['_id']}_2500.png";
          }
        }
      }
    }
    return "broken image"; // Return a default URL or a placeholder for no match
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
      child: Column(children: [
        imageLoaded
            ? CachedNetworkImage(
          imageUrl: imageUrl,
          width: 60,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) =>
              Image.asset("assets/imgs/angry.png", width: 60),
        )
            : Container(), // Show an empty container or a placeholder while loading
        Text(widget.word,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
      ]),
    );
  }
}