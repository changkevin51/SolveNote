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
                  "Solve the math expression in this image step-by-step. Return a valid JSON object with two keys: 'solution' and 'steps'. IMPORTANT: Use proper JSON format with double quotes for all keys and string values (not single quotes). The 'solution' key should contain ONLY the final numerical answer or simplified expression as a clean LaTeX string (NO additional text like 'where n is an integer'). The 'steps' key should contain a single markdown string with the detailed steps, including any necessary explanations about variables or constraints. IMPORTANT: In the markdown, all LaTeX (formulas, variables, symbols) must be enclosed in single dollar signs (e.g., \$x^2 + y^2 = z^2\$). Ensure backslashes in LaTeX are properly escaped for JSON (e.g., '\\frac' becomes '\\\\frac'). Write each step as a complete sentence starting with a capital letter - NEVER start a line with '. ' (period and space). Each line should be a complete thought ending with proper punctuation. When a sentence ends with a math equation, put the period immediately after the closing \$ sign, like: 'The equation becomes \$x = 5\$.' NOT on the next line. CRITICAL: When writing fractions (\\frac{...}{...}) or complex multi-line expressions, DO NOT add any punctuation (periods, commas, etc.) after them. Instead, just end the line with the closing \$ sign. For simple expressions like \$x = 5\$ you can add punctuation, but for fractions and complex expressions, omit all trailing punctuation to prevent formatting issues. Start each new equation on its own line when possible."
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

    print('Raw AI response: $content');

    // Clean the content more thoroughly
    String cleanedContent = content.trim();

    // Remove markdown code blocks
    cleanedContent =
        cleanedContent.replaceAll('```json', '').replaceAll('```', '').trim();

    // Try to extract JSON from the response if it's wrapped in other text
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedContent);
    if (jsonMatch != null) {
      cleanedContent = jsonMatch.group(0)!;
    }

    print('Cleaned content for parsing: $cleanedContent');

    late Map<String, dynamic> solutionMap;
    try {
      solutionMap = jsonDecode(cleanedContent);
    } catch (e) {
      print('JSON parsing error: $e');
      print('Attempting to fix common JSON issues...');

      // Try to fix common JSON issues
      String fixedContent = cleanedContent;

      // Fix single quotes to double quotes for JSON keys and string values
      // First, protect escaped quotes inside strings
      fixedContent = fixedContent.replaceAll(r"\'", "___ESCAPED_QUOTE___");

      // Replace single quotes with double quotes
      fixedContent = fixedContent.replaceAll("'", '"');

      // Restore escaped quotes
      fixedContent = fixedContent.replaceAll("___ESCAPED_QUOTE___", r"\'");

      // Fix unescaped backslashes in LaTeX (but not the ones we just fixed)
      fixedContent = fixedContent.replaceAllMapped(
        RegExp(r'\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})'),
        (match) => '\\\\',
      );

      print('Fixed content: $fixedContent');

      try {
        solutionMap = jsonDecode(fixedContent);
      } catch (e2) {
        print('Still failed to parse JSON: $e2');
        return null;
      }
    }

    String cleanLatex(String input) {
      var result = input.trim();

      // Remove outer LaTeX delimiters
      if (result.startsWith(r'\(') && result.endsWith(r'\)')) {
        result = result.substring(2, result.length - 2).trim();
      }
      if (result.startsWith(r'$$') && result.endsWith(r'$$')) {
        result = result.substring(2, result.length - 2).trim();
      }
      if (result.startsWith(r'$') && result.endsWith(r'$')) {
        result = result.substring(1, result.length - 1).trim();
      }

      // Remove any remaining isolated dollar signs that might interfere with math mode
      // But preserve escaped dollar signs \$
      result = result.replaceAllMapped(RegExp(r'(?<!\\)\$'), (match) => '');

      return result;
    }

    String cleanSteps(String input) {
      String result = input.trim();

      // AGGRESSIVE: Remove punctuation that follows fractions completely
      // Match fractions followed by punctuation (with or without whitespace/newlines)
      result = result.replaceAllMapped(
          RegExp(r'(\$[^$]*\\frac[^$]*\$)\s*[,.;:!?]\s*'), (match) {
        return '${match.group(1)} ';
      });

      // Also remove punctuation after any complex expressions ending with }
      result = result.replaceAllMapped(RegExp(r'(\$[^$]*\})\$\s*[,.;:!?]\s*'),
          (match) {
        return '${match.group(1)}\$ ';
      });

      // Remove punctuation after sqrt expressions
      result = result.replaceAllMapped(
          RegExp(r'(\$[^$]*\\sqrt[^$]*\$)\s*[,.;:!?]\s*'), (match) {
        return '${match.group(1)} ';
      });

      // For other math expressions, try to fix the punctuation placement
      // Handle patterns like "$equation$\n." or "$equation$\n. " or "$equation$ \n."
      result = result.replaceAllMapped(
          RegExp(r'\$([^$]+)\$\s*\n\s*([,.;:!?])\s*'), (match) {
        // Only attach punctuation if it's NOT after a fraction or complex expression
        final equation = match.group(1)!;
        if (equation.contains('\\frac') || equation.endsWith('}')) {
          return '\$${equation}\$ ';
        }
        return '\$${equation}\$${match.group(2)} ';
      });

      // Handle punctuation directly after equations but separated by spaces
      result =
          result.replaceAllMapped(RegExp(r'\$([^$]+)\$\s+([,.;:!?])'), (match) {
        final equation = match.group(1)!;
        if (equation.contains('\\frac') || equation.endsWith('}')) {
          return '\$${equation}\$ ';
        }
        return '\$${equation}\$${match.group(2)}';
      });

      // Fix cases where punctuation starts a line after any content (not just equations)
      result = result.replaceAllMapped(RegExp(r'(\S)\s*\n\s*([,.;:!?])\s*'),
          (match) {
        return '${match.group(1)}${match.group(2)} ';
      });

      // Handle general cases where punctuation starts a line
      result = result.replaceAllMapped(RegExp(r'\n\s*([,.;:!?])\s*'), (match) {
        return '${match.group(1)} ';
      });

      // More aggressive: find any isolated punctuation and try to attach it to previous line
      final lines = result.split('\n');
      final cleanedLines = <String>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // If this line starts with punctuation, try to attach it to the previous line
        if (line.isNotEmpty && RegExp(r'^[,.;:!?]').hasMatch(line)) {
          if (cleanedLines.isNotEmpty) {
            final prevLine = cleanedLines.last;
            // Check if the previous line ends with a fraction - if so, don't attach punctuation
            if (RegExp(r'\$[^$]*\\frac[^$]*\$\s*$').hasMatch(prevLine) ||
                RegExp(r'\$[^$]*\}\$\s*$').hasMatch(prevLine)) {
              // Skip the punctuation entirely for fractions
              if (line.length > 1) {
                cleanedLines.add(line.substring(1).trim());
              }
            } else {
              // Remove the previous line and add it back with the punctuation attached
              cleanedLines[cleanedLines.length - 1] =
                  prevLine + line.substring(0, 1);
              // Add the rest of the line if there's more content
              if (line.length > 1) {
                cleanedLines.add(line.substring(1).trim());
              }
            }
          } else {
            cleanedLines.add(line); // Keep it if there's no previous line
          }
        } else {
          cleanedLines.add(
              lines[i]); // Preserve original formatting including empty lines
        }
      }

      result = cleanedLines.join('\n');

      // Handle cases where the period is at the start of the string
      if (result.startsWith('. ')) {
        result = result.substring(2);
      }

      // Add extra spacing around equations that contain fractions or complex expressions
      // This helps prevent overlapping of LaTeX content
      result =
          result.replaceAllMapped(RegExp(r'(\$[^$]*\\frac[^$]*\$)'), (match) {
        return '\n${match.group(0)}\n';
      });

      // Add spacing around display-style equations (those on their own lines)
      result = result.replaceAllMapped(RegExp(r'\n(\$[^$]+\$)\n'), (match) {
        return '\n\n${match.group(1)}\n\n';
      });

      // Clean up excessive newlines but allow for the spacing we just added
      result = result.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');

      // Remove excessive newlines at the start and end
      result = result.replaceAll(RegExp(r'^\n+'), '');
      result = result.replaceAll(RegExp(r'\n+$'), '');

      return result;
    }

    return {
      'solution': cleanLatex(solutionMap['solution'] as String),
      'steps': cleanSteps(solutionMap['steps'] as String),
    };
  }
}
