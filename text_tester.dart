import 'dart:io';

import 'package:edu_chatbot/util/functions.dart';

const String mm = '💛💛💛💛 TextTester' ;
void main() {
  String filePath = 'text.txt';
  try {
    String fileContent = readStringFromFile(filePath);
    pp('$mm File Content:');
    pp(fileContent);

    List<String> paragraphs = detectParagraphs(fileContent);
    pp('$mm Paragraphs found in text: ${paragraphs.length}');


    List<String> filtered = [];
    var uppers = detectUppercaseWords(fileContent);
    for (var value in uppers) {
      if (double.tryParse(value.trim()) != null) {
        continue;
      }
      var splits = value.split('.');
      if (splits.length > 1) {
        continue;
      }
      // var splits2 = value.split('(');
      // if (splits2.isNotEmpty) {
      //   continue;
      // }
      if (value == 'ANSWER' || value == 'BOOK' || value == 'NSC') {
        continue;
      }
      pp('$mm uppercase word found: $value');
      filtered.add(value);
    }
    var modified = addNewLineAfterOccurrences(fileContent, filtered);
    pp('$mm .... modified string ....');
    pp(modified);
    pp(convertToMarkdown(modified));
  } catch (e) {
    pp('$mm Error: $e');
  }
}
String convertToMarkdown(String text) {
  List<String> lines = text.split('\n');
  String markdownString = '';

  for (String line in lines) {
    if (line.isNotEmpty) {
      if (isUppercase(line)) {
        markdownString += '\n\n## $line\n';
      } else {
        markdownString += line + '\n';
      }
    }
  }

  return markdownString;
}

String addNewLineAfterOccurrences(String text, List<String> keywords) {
  String modifiedText = text;
  for (String keyword in keywords) {
    modifiedText = modifiedText.replaceAll(keyword, '\n\n$keyword');
  }
  return modifiedText;
}
List<String> detectUppercaseWords(String text) {
  // Split the text into words
  List<String> words = text.split(' ');

  // Create a list to store the uppercase words
  List<String> uppercaseWords = [];

  // Iterate through each word and check if it is uppercase and has a length greater than 2
  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (isUppercase(word) && word.length > 2 && !isNumeric(word)) {
      // Add the uppercase word to the list
      uppercaseWords.add(word);
    }
  }

  return uppercaseWords;
}

bool isUppercase(String word) {
  for (int i = 0; i < word.length; i++) {
    if (word[i] != word[i].toUpperCase()) {
      return false;
    }
  }
  return true;
}

bool isNumeric(String s) {
  return int.tryParse(s) != null || double.tryParse(s) != null;
}

List<String> detectParagraphs(String text) {
  // Split the text into paragraphs based on double line breaks
  List<String> paragraphs = text.split('\n\n');

  // Remove leading and trailing whitespace from each paragraph
  paragraphs = paragraphs.map((paragraph) => paragraph.trim()).toList();

  return paragraphs;
}

String readStringFromFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('File does not exist: $filePath');
  }
  return file.readAsStringSync();
}
