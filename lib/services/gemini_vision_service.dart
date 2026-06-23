import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> analyzeImage(String imagePath) async {
    print('API Length: ${apiKey.length}');

    if (apiKey.length >= 8) {
      print('API Start: ${apiKey.substring(0, 8)}...');
    }

    print('Full API: $apiKey');
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are Twinkle's helper in a children's learning game called Twinkle's Rainbow Hunt.

A child aged 3-8 years has taken a photo.

Your task is to identify the MAIN object in the image.

IMPORTANT RULES:

- Return EXACTLY ONE object name.
- Use simple words a child understands.
- Use singular words only.
- Choose the largest or most obvious object.
- If multiple objects exist, choose the main one.
- Prefer common home, school, toy, food, clothing, animal, and nature objects.

Examples of good answers:

Bottle
Book
Chair
Table
Toy
Ball
Cup
Spoon
Apple
Banana
Flower
Leaf
Bag
Notebook
Pencil
Crayon
Shoe
Shirt
Pillow
Phone
Laptop
Remote
Plant
Dog
Cat

Do NOT return:
- Sentences
- Explanations
- Colors
- Brands
- Confidence scores
- Multiple objects
- JSON
- Markdown

Return only the object name.
"""
                },
                {
                  "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
                }
              ]
            }
          ],
          // "generationConfig": {
          //   "temperature": 0.1,
          //   "topK": 1,
          //   "topP": 0.8,
          //   "maxOutputTokens": 10
          // }
        }),
      );

      print("Gemini Status: ${response.statusCode}");
      print("Gemini Body: ${response.body}");

      if (response.statusCode != 200) {
        return 'Treasure';
      }

      final data = jsonDecode(response.body);

      String result =
          data['candidates'][0]['content']['parts'][0]['text']?.toString() ??
              'Treasure';

      result = result
          .trim()
          .replaceAll('"', '')
          .replaceAll('.', '')
          .replaceAll(':', '')
          .split('\n')
          .first
          .trim();

      if (result.isEmpty) {
        return 'Treasure';
      }

      debugPrint('Gemini Detected Object: $result');

      return result;
    } catch (e) {
      debugPrint('Gemini Exception: $e');
      return 'Treasure';
    }
  }
}
