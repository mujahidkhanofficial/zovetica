// AI Service for Groq Integration via HTTP
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqAiService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _apiKey;
  
  GroqAiService() : _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  /// Send a message to Groq AI and get a response
  Future<String> sendMessage(String userMessage, {String? petContext}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Groq API key not found. Please add GROQ_API_KEY to your .env file');
    }

    // Build system prompt with veterinary context
    final systemPrompt = _buildSystemPrompt(petContext);
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // Fast Groq model
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'] as String;
        return aiMessage.trim();
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your GROQ_API_KEY in .env file');
      } else {
        throw Exception('Failed to get AI response (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error communicating with AI: $e');
    }
  }

  /// Build system prompt for veterinary AI assistant
  String _buildSystemPrompt(String? petContext) {
    String basePrompt = '''You are VetAI, a helpful and empathetic veterinary AI assistant for Pets & Vets, a pet healthcare app.

Your role:
- Provide general pet health information and guidance
- Answer questions about pet care, nutrition, and common symptoms
- Recommend when professional veterinary care is needed
- Be supportive and reassuring to concerned pet owners

Important guidelines:
- NEVER diagnose or replace professional veterinary care
- Always recommend visiting a vet for serious symptoms
- Be concise but informative (keep responses under 200 words)
- Use simple, friendly language
- Show empathy for worried pet owners''';

    if (petContext != null && petContext.isNotEmpty) {
      basePrompt += '\n\nPet context: $petContext';
    }

    return basePrompt;
  }

  /// Get suggested questions for quick interaction
  List<String> getSuggestedQuestions() {
    return [
      'What should I feed my dog?',
      'How often should I walk my cat?',
      'Signs of illness in pets',
      'Vaccination schedule for puppies',
      'How to calm an anxious pet',
      'Common pet allergies',
    ];
  }
}
