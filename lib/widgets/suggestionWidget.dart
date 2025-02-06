import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/ai_utility.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dialogWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.9
        : MediaQuery.of(context).size.width * 0.6;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      content: Stack(
        children: [
          Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              border: GradientBoxBorder(
                gradient: LinearGradient(
                    colors: [Color(0xFFAC70F8), Color(0xFFFF79FD)]),
                width: 4,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: Colors.white,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientText(
                    'Sentence Helper',
                    gradient: LinearGradient(
                        colors: [Color(0xFFAC70F8), Color(0xFF7000FF)]),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          isMobile ? 36 : 48, // Adjusted font size for mobile
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: 300,
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: isLoading
                        ? Center(
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(),
                            ),
                          )
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
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 24,
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

  AISuggestion({
    required this.phrase,
    required this.pictogramsData,
    required this.homePageKey,
  });

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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final buttonSize = isMobile ? 40.0 : 50.0;
    final iconSize = isMobile ? 20.0 : 30.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Phrase area with horizontal scrolling
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.phrase.split(' ').map((word) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PhraseColumn(
                      word: word,
                      pictogramsData: widget.pictogramsData,
                      onImageAdded: (imageUrl) {
                        setState(() {
                          imageUrls.add(imageUrl);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Play button
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await _stopPhrase();
                } else {
                  await _speakPhrase();
                }
              },
              child: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8),
          // Select button
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                final homePageState = widget.homePageKey.currentState;
                if (homePageState != null) {
                  homePageState.addPhraseToTopBar(widget.phrase, imageUrls);
                }
                Navigator.of(context).pop();
              },
              child: Icon(
                Icons.check,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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
  late String brokenurl;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    await _initializeBrokenUrl();
    String fetchedImageUrl =
        await _retryLoadImage(widget.pictogramsData, widget.word);
    setState(() {
      imageUrl = fetchedImageUrl.isNotEmpty ? fetchedImageUrl : brokenurl;
      imageLoaded = true;
    });
    widget.onImageAdded(imageUrl);
  }

  Future<void> _initializeBrokenUrl() async {
    brokenurl = await copyFallbackToLocalDir();
  }

  Future<String> copyFallbackToLocalDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final String localImagePath = '${directory.path}/fallback_image.png';

    if (!File(localImagePath).existsSync()) {
      final ByteData data =
          await rootBundle.load('assets/imgs/fallback_image.png');
      final buffer = data.buffer;
      await File(localImagePath).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    print("Local Image Path: $localImagePath");
    return localImagePath;
  }

  Future<String> _retryLoadImage(List<dynamic> data, String keyword) async {
    String result = "broken image";
    for (int retryCount = 0; retryCount < maxRetries; retryCount++) {
      result = await searchButtonData(data, keyword);
      if (result != "broken image" && result.isNotEmpty) {
        return result;
      }
      print("Retry #$retryCount failed for word: $keyword");
      await Future.delayed(Duration(seconds: 1));
    }
    print("Failed to fetch image after $maxRetries retries for word: $keyword");
    return result;
  }

  Future<String> searchButtonData(List<dynamic> data, String keyword) async {
    keyword = keyword.trim().toLowerCase();
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey("keywords")) {
        for (var keywordData in item["keywords"]) {
          if (keywordData["keyword"].toString().toLowerCase() == keyword) {
            print("Found keyword: $keyword");
            print(
                "https://static.arasaac.org/pictograms/${item['_id']}/${item['_id']}_2500.png");
            return "https://static.arasaac.org/pictograms/${item['_id']}/${item['_id']}_2500.png";
          }
        }
      }
    }
    return "broken image";
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final imageSize = isMobile ? 50.0 : 100.0;
    final fontSize = isMobile ? 14.0 : 28.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          imageLoaded
              ? CachedNetworkImage(
                  imageUrl: imageUrl.startsWith('http')
                      ? imageUrl
                      : 'file://$imageUrl',
                  width: imageSize,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) {
                    print("Image failed to load: $url, Error: $error");
                    return Image.file(File(brokenurl), width: imageSize);
                  },
                )
              : CircularProgressIndicator(),
          SizedBox(height: 4),
          Text(
            widget.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
