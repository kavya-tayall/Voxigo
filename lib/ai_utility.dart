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
// need to fix the fetchchildbuttonsdata so it gets the string correctly
  String childData = await Provider.of<ChildProvider>(context, listen: false).fetchChildButtonsData();
  try{
    if (apiKey != null){
      print(apiKey);
      String prompt =
          '''
          below are phrases the child has used in the past. give me suggestions for phrases that the child might type out now. so far she has typed "$currentPhrase" in the AAC board, so give me top 5 suggestions in order from most likely to least likely according to the data and basic commonality of the phrases. The suggestions should be formatted in a list, with each phrase being a comma-separated element with quotes around it like so: ["phrase1", "phrase2", "phrase3"...]. I only want this list in your response, nothing else. 
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

Future<String?> generateResponse(String message, String childData, BuildContext context) async {
  try{
    if (apiKey != null){
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey!,
      );

      String prompt =
      ''' 
      The admin of the child has sent the following message: $message. The data in $childData, answer the response about their child. Don't just summarize it--you need to give insights and general statements after interpreting the data. be thorough and give good summaries of their children. make sure the response doesn't have any special formatting such as bold, italics, etc. because it doesnt show up. be friendly and conversational. dont make it multiple paragraphs, but between 1-3 is good. dont yap and be direct but thorough. also dont talk about "this app" but rather just reference the child and his/her actions. only respond with a response that uses the data given if the prompt has indicated that it wants a response containing info from the data. for example, if they just say something like "thank you", no need to use the data, the response can just be normal.
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





