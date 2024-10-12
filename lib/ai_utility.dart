import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:test_app/widgets/child_provider.dart';

final apiKey = Platform.environment['GOOGLE_API_KEY'];

final model = GenerativeModel(
  model: 'gemini-1.5-flash-latest',
  apiKey: apiKey!,
);


final safetySettings = [
  SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
  SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
  SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
];


Future<String?> generateSentenceSuggestion(String currentPhrase, BuildContext context) async {
  String childData = await Provider.of<ChildProvider>(context, listen: false).fetchChildSelectedButtons();
  try{
    if (apiKey != null){
      print(apiKey);
      String prompt =
          '''
          below are phrases the child has used in the past. give me suggestions for phrases that the child might type out now. so far she has typed "$currentPhrase" in the AAC board, so give me top 5 suggestions in order from most likely to least likely according to how often the prhase was clicked, and type types of phrases clicked. The suggestions should be formatted in a list, with each phrase being a comma-separated element with quotes around it like so: ["phrase1", "phrase2", "phrase3"...]. I only want this list in your response, nothing else. 
          $childData
          ''';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content, safetySettings: safetySettings);

      return response.text;
    } else{
      print("dont work");
    }
  } catch(e){
    print("ai not working: $e");
  }
  return null;
}

Future<String?> generateSummary(List selectedData, String type) async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];

  try{
    if (apiKey != null){
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );
      String embeddedStringNewline = selectedData.map((item) => item['phrase'] ?? '').join('\n');
      print(embeddedStringNewline);
      String prompt =
      ''' 
      Summarize the below data. This data is about what $type the child clicked in the app. Give a summary based on the timestamps and ${type} provided.
      ${embeddedStringNewline}
          ''';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text;
    } else{
      print("dont work");
    }
  } catch(e){
    print("ai not working: $e");
  }
  return null;
}





