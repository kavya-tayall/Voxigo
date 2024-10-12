import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';


Future<String?> generateSentenceSuggestion(String currentPhrase) async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];

  try{
    if (apiKey != null){
      print(apiKey);
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey!,
      );
      print(model);

      String prompt =
          '''
          below are phrases the child has used in the past. give me suggestions for phrases that the child might type out now. so far she has typed "$currentPhrase" in the AAC board, so give me top 5 suggestions in order from most likely to least likely according to that. The suggestions should be formatted in a python list, with each phrase being a comma-separated element. I only want the suggestions in your response, nothing else. 
          aac_data = [
    {"phrase": "I want juice", "timestamp": "10:12:05"},
    {"phrase": "I'm tired", "timestamp": "10:15:45"},
    {"phrase": "Help me", "timestamp": "10:17:32"},
    {"phrase": "I need a break", "timestamp": "10:21:10"},
    {"phrase": "I want to play", "timestamp": "10:22:57"},
    {"phrase": "No", "timestamp": "10:25:19"},
    {"phrase": "Yes", "timestamp": "10:26:50"},
    {"phrase": "I'm hungry", "timestamp": "10:30:22"},
    {"phrase": "I love you", "timestamp": "10:35:08"},
    {"phrase": "I don't like that", "timestamp": "10:37:12"},
    {"phrase": "Can I go outside?", "timestamp": "10:40:45"},
    {"phrase": "I'm happy", "timestamp": "10:43:11"},
    {"phrase": "It's loud", "timestamp": "10:45:33"},
    {"phrase": "I need help", "timestamp": "10:47:22"},
    {"phrase": "Please", "timestamp": "10:50:10"},
    {"phrase": "I'm cold", "timestamp": "10:52:30"},
    {"phrase": "All done", "timestamp": "10:53:44"},
    {"phrase": "I don't want that", "timestamp": "10:57:19"},
    {"phrase": "Can I have a snack?", "timestamp": "10:59:06"},
    {"phrase": "I want more", "timestamp": "11:01:15"},
    {"phrase": "I don't understand", "timestamp": "11:03:25"},
    {"phrase": "I want water", "timestamp": "11:05:02"},
    {"phrase": "I'm scared", "timestamp": "11:07:14"},
    {"phrase": "Play with me", "timestamp": "11:08:50"},
    {"phrase": "I need to go to the bathroom", "timestamp": "11:10:25"},
    {"phrase": "I like that", "timestamp": "11:12:19"},
    {"phrase": "Can I have that?", "timestamp": "11:13:44"},
    {"phrase": "What is that?", "timestamp": "11:15:55"},
    {"phrase": "I feel sick", "timestamp": "11:17:30"},
    {"phrase": "I'm hot", "timestamp": "11:20:10"},
    {"phrase": "Can I watch TV?", "timestamp": "11:21:32"},
    {"phrase": "I want to read", "timestamp": "11:23:12"},
    {"phrase": "Let's go", "timestamp": "11:25:44"},
    {"phrase": "I'm sad", "timestamp": "11:27:06"},
    {"phrase": "I like you", "timestamp": "11:29:15"},
    {"phrase": "Where is mom?", "timestamp": "11:30:50"},
    {"phrase": "No thank you", "timestamp": "11:33:22"},
    {"phrase": "I want to go home", "timestamp": "11:35:14"},
    {"phrase": "I'm thirsty", "timestamp": "11:37:48"},
    {"phrase": "I want a hug", "timestamp": "11:40:00"},
    {"phrase": "What's your name?", "timestamp": "11:42:19"},
    {"phrase": "I like this game", "timestamp": "11:44:52"},
    {"phrase": "I want to sleep", "timestamp": "11:47:35"},
    {"phrase": "Can I have my toy?", "timestamp": "11:49:22"},
    {"phrase": "Turn it off", "timestamp": "11:50:58"},
    {"phrase": "More please", "timestamp": "11:53:10"},
    {"phrase": "I don't like this", "timestamp": "11:55:34"},
    {"phrase": "I'm bored", "timestamp": "11:57:48"},
    {"phrase": "I'm full", "timestamp": "11:59:10"},
    {"phrase": "I want to sing", "timestamp": "12:00:22"},
    {"phrase": "Read to me", "timestamp": "12:02:30"},
    {"phrase": "My head hurts", "timestamp": "12:05:11"},
    {"phrase": "Can I go outside?", "timestamp": "12:07:33"},
    {"phrase": "Turn it up", "timestamp": "12:09:20"},
    {"phrase": "I want to dance", "timestamp": "12:11:45"},
    {"phrase": "I'm upset", "timestamp": "12:13:32"},
    {"phrase": "Play music", "timestamp": "12:15:09"},
    {"phrase": "Where is dad?", "timestamp": "12:16:57"},
    {"phrase": "I want to color", "timestamp": "12:18:43"},
    {"phrase": "Can I play with that?", "timestamp": "12:20:10"},
    {"phrase": "It's too bright", "timestamp": "12:21:50"},
    {"phrase": "I'm sleepy", "timestamp": "12:23:33"},
    {"phrase": "Can I eat?", "timestamp": "12:25:10"},
    {"phrase": "I don't feel good", "timestamp": "12:26:42"},
    {"phrase": "Stop it", "timestamp": "12:28:15"},
    {"phrase": "I want mommy", "timestamp": "12:30:22"},
    {"phrase": "I'm excited", "timestamp": "12:32:11"},
    {"phrase": "It's too loud", "timestamp": "12:34:00"},
    {"phrase": "Can we go?", "timestamp": "12:35:42"},
    {"phrase": "I'm angry", "timestamp": "12:37:30"},
    {"phrase": "I want to play a game", "timestamp": "12:39:15"},
    {"phrase": "Can I have more?", "timestamp": "12:41:10"},
    {"phrase": "I want to draw", "timestamp": "12:43:22"},
    {"phrase": "I'm frustrated", "timestamp": "12:45:44"},
    {"phrase": "I want to go to the park", "timestamp": "12:47:12"},
    {"phrase": "I'm tired", "timestamp": "12:49:30"},
    {"phrase": "Can I have water?", "timestamp": "12:51:19"},
    {"phrase": "I'm scared", "timestamp": "12:52:55"},
    {"phrase": "I don't want to go", "timestamp": "12:54:44"},
    {"phrase": "Can I watch a movie?", "timestamp": "12:56:22"},
    {"phrase": "I want my blanket", "timestamp": "12:58:10"},
    {"phrase": "I want to go swimming", "timestamp": "13:00:05"},
    {"phrase": "I don't like that", "timestamp": "13:01:20"},
    {"phrase": "I'm cold", "timestamp": "13:03:19"},
    {"phrase": "Can we play?", "timestamp": "13:05:00"},
    {"phrase": "Can I go to bed?", "timestamp": "13:06:48"},
    {"phrase": "I want my teddy bear", "timestamp": "13:08:30"},
    {"phrase": "I'm not feeling well", "timestamp": "13:10:12"},
    {"phrase": "Can I have a cookie?", "timestamp": "13:11:55"},
    {"phrase": "I need help", "timestamp": "13:13:25"},
    {"phrase": "I'm sad", "timestamp": "13:15:02"},
    {"phrase": "Can I go with you?", "timestamp": "13:16:50"},
    {"phrase": "Turn it down", "timestamp": "13:18:15"},
    {"phrase": "Where's my toy?", "timestamp": "13:19:50"},
    {"phrase": "I'm frustrated", "timestamp": "13:21:22"},
    {"phrase": "I love you", "timestamp": "13:23:33"},
    {"phrase": "I want to read a book", "timestamp": "13:25:10"},
]
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





