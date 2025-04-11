import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<String> textSplit(String input, {int maxLength = 20}) {
  List<String> words = input.split(' '); // Split by space
  List<String> result = [];
  String currentLine = "";

  for (String word in words) {
    if ((currentLine + word).length <= maxLength) {
      currentLine += (currentLine.isEmpty ? "" : " ") + word;
    } else {
      result.add(currentLine);
      currentLine = word;
    }
  }

  if (currentLine.isNotEmpty) {
    result.add(currentLine);
  }

  return result;
}

DateTime? parseAutoDate(String? dateString) {
  // Define patterns for different date formats
  final isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$'); // YYYY-MM-DD
  final dmyPattern = RegExp(r'^\d{2}-\d{2}-\d{4}$'); // DD-MM-YYYY

  if (dateString == null) {
    return null;
  }

  if (isoPattern.hasMatch(dateString)) {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  } else if (dmyPattern.hasMatch(dateString)) {
    return DateFormat('dd-MM-yyyy').parse(dateString);
  } else {
    return null; // Handle unsupported formats
  }
}

String formatDateLocalized(String dateString, BuildContext context) {
  return DateFormat("dd MMM yyyy", Localizations.localeOf(context).toString()).format(parseAutoDate(dateString)!).toUpperCase();
}