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

    if (pictogramsData != null && suggestions.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
    }
  }
//hi

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      content: Stack(
        children: [

          Container(
            decoration: BoxDecoration(
              border: GradientBoxBorder(
                gradient: LinearGradient(colors: [Color(0xFFAC70F8), Color(0xFFFF79FD)]),
                width: 4,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  GradientText(
                    'Sentence Helper',
                    gradient: LinearGradient(colors: [Color(0xFFAC70F8), Color(0xFF7000FF)]),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 60,
                    ),
                  ),
                  SizedBox(height: 16),

                  Expanded(
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
                            homePageKey: widget.homePageKey,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



}

class AISuggestion extends StatefulWidget {
  final String phrase;
  final dynamic pictogramsData;
  final GlobalKey<HomePageState> homePageKey;

  AISuggestion({required this.phrase, required this.pictogramsData, required this.homePageKey});

  @override
  State<AISuggestion> createState() => _AISuggestionState();
}

class _AISuggestionState extends State<AISuggestion> {
  FlutterTts flutterTts = FlutterTts();
  List<String> imageUrls = [];
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);


    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
      });
    });
  }

  Future<void> _speakPhrase() async {
    setState(() {
      isPlaying = true;
    });

    await flutterTts.speak(widget.phrase);


    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }


  Future<void> _stopPhrase() async {
    await flutterTts.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> words = widget.phrase.split(' ');

    return Column(children: [
      SizedBox(
        height: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: words.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: PhraseColumn(
                      word: words[index],
                      pictogramsData: widget.pictogramsData,
                      onImageAdded: (imageUrl) {
                        setState(() {
                          imageUrls.add(imageUrl);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.blue,
                  minimumSize: Size(80, 80),
                ),
                onPressed: () async {
                  if (isPlaying) {
                    await _stopPhrase();
                  } else {
                    await _speakPhrase();
                  }
                },

                child: isPlaying
                    ? Icon(Icons.stop, size: 40, color: Colors.white)
                    : Icon(Icons.play_arrow_sharp, size: 40, color: Colors.white),
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.blue,
                  minimumSize: Size(80, 80),
                ),
                onPressed: () {
                  final homePageState = widget.homePageKey.currentState;
                  if (homePageState != null) {
                    homePageState.addPhraseToTopBar(widget.phrase, imageUrls);
                  }
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.check, size: 40, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      Divider(
        thickness: 1.5,
        color: Colors.grey.shade300,
        height: 10,
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
  bool imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    String fetchedImageUrl = await searchButtonData(widget.pictogramsData, widget.word);
    setState(() {
      imageUrl = fetchedImageUrl;
      imageLoaded = true;
    });
    widget.onImageAdded(imageUrl);
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
    return "broken image";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(children: [
        imageLoaded
            ? CachedNetworkImage(
          imageUrl: imageUrl,
          width: 100,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) =>
              Image.asset("assets/imgs/angry.png", width: 100),
        )
            : Container(),
        SizedBox(height: 4),
        Text(
          widget.word,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 28,
          ),
        ),
      ]),
    );
  }
}
