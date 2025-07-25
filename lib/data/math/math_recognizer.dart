import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/math/math_expression.dart';

class MathRecognizer {
  final String _apiKey;

  MathRecognizer(this._apiKey);

  Future<Map<String, String>?> recognize(Uint8List imageBytes) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    // Validate API key
    if (_apiKey.isEmpty) {
      print('Error: API key is empty');
      return null;
    }

    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': _apiKey,
    };

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Solve the math expression in this image step-by-step. Return a valid JSON object with two keys: 'solution' and 'steps'. The 'solution' key should contain the final answer as a LaTeX string. The 'steps' key should contain a single markdown string with the detailed steps. IMPORTANT: In the markdown, all LaTeX (formulas, variables, symbols) must be enclosed in single dollar signs (e.g., \$x^2 + y^2 = z^2\$). Ensure backslashes in LaTeX are properly escaped for JSON (e.g., '\\frac' becomes '\\\\frac')."
            },
            {
              "inline_data": {
                "mime_type": "image/png",
                "data": base64Encode(imageBytes)
              }
            }
          ]
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$url?key=$_apiKey'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('API Response Status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
      print('Body: ${response.body}');
      return null;
    }

    final jsonResponse = jsonDecode(response.body);
    final content =
        jsonResponse['candidates'][0]['content']['parts'][0]['text'];
    final cleanedContent =
        content.replaceAll('```json', '').replaceAll('```', '').trim();
    final Map<String, dynamic> solutionMap = jsonDecode(cleanedContent);

    String cleanLatex(String input) {
      var result = input.trim();
      if (result.startsWith(r'\(') && result.endsWith(r'\)')) {
        return result.substring(2, result.length - 2).trim();
      }
      if (result.startsWith(r'$$') && result.endsWith(r'$$')) {
        return result.substring(2, result.length - 2).trim();
      }
      if (result.startsWith(r'$') && result.endsWith(r'$')) {
        return result.substring(1, result.length - 1).trim();
      }
      return result;
    }

    return {
      'solution': cleanLatex(solutionMap['solution'] as String),
      'steps': solutionMap['steps'] as String,
    };
  }
}
