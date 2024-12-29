import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:test_app/cache_utility.dart';

final String apiKey =
    "AIzaSyBHQlIUwg0FCaSMud4U-vFBIWoGi9VratU"; // Replace with actual API key

final safetySettings = [
  SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
  SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
  SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
];

Future<String?> generateSentenceSuggestion(
    String currentPhrase, BuildContext context) async {
  try {
    DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

    // Fetch child data
    String childData = await fetchChildrenAnonDataforAI(
        filterDate: sevenDaysAgo, byParent: false);

    // Create a new model instance
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    // Define the prompt
    String prompt = '''
      $childData has buttonsData phrases the child has used in the past. Provide suggestions for phrases the child might type now. 
      So far, the child has typed "$currentPhrase" on the AAC board. Give the top 5 suggestions in a list format: 
      ["phrase1", "phrase2", "phrase3", ...]. Use grammatically correct English and also suggest possible English sentences can be framed using the words in "$currentPhrase". 
      Do not include anything else in the response.
    ''';

    // Generate content
    final content = [Content.text(prompt)];
    final response =
        await model.generateContent(content, safetySettings: safetySettings);

    return response.text;
  } catch (e) {
    print("Error generating sentence suggestion: $e");
    return null;
  }
}

Future<String?> generateResponse(
    String message, String childData, BuildContext context) async {
  try {
    // Create a new model instance
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    // Define the prompt
    String prompt = '''
      Admin has this message: "$message". If this message has single word then ask for clarification. If message is clear then using the child's data: $childData, provide a response.Focus on insights and general statements about the child.
      For privacy reasons, we will never send any name in $message" but send an identifier in message that you can related to userReference in $childData . 
      Be concise but thorough in 3 sentences. Avoid formatting like bold, italics, or special characters. 
      If the message is not clear, ask for clarification instead of generating a response and not use $childData. 
      For single words just say , please be clear and provide more context for your question.
       When message is vauge and not clear, reply in simple english , greet user for general english greetings and ask for clarification. 
       In case of irrelavant messages Do not repat the message or words used in response. r
''';
    // Generate content
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    return response.text;
  } catch (e) {
    print("Error generating response: $e");
    return null;
  }
}
