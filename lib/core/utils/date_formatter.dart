// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dart:math'; // For min function if used in StoryService log

class DateFormatter {
  // Formats a date relative to now (e.g., "5h ago", "Mar 10, 2024")
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }
    // Check for potentially uninitialized/default dates from backend/parsing
    if (dateTime.year <= 1 || dateTime.millisecondsSinceEpoch <= 0) {
      if (kDebugMode)
        print(
            "DateFormatter: Encountered potentially invalid date: $dateTime. Returning 'N/A'.");
      return 'N/A';
    }

    final now = DateTime.now();
    // Handle future dates gracefully
    if (dateTime.isAfter(now)) {
      // If it's *very* slightly after now (e.g., due to clock sync), treat as 'Just now'
      if (dateTime.difference(now).inSeconds < 5) {
        return 'Just now';
      }
      // Otherwise, show the actual future date
      if (kDebugMode)
        print(
            "DateFormatter: Encountered future date: $dateTime. Formatting as absolute date.");
      return DateFormat('MMM d, yyyy').format(dateTime);
    }

    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  // Formats a date into a specific pattern (e.g., "March 10, 2024")
  static String formatAbsoluteDate(DateTime? dateTime,
      {String pattern = 'MMM d, yyyy'}) {
    if (dateTime == null) {
      return 'N/A';
    }
    // Check for potentially uninitialized/default dates
    if (dateTime.year <= 1 || dateTime.millisecondsSinceEpoch <= 0) {
      if (kDebugMode)
        print(
            "DateFormatter: Encountered potentially invalid date: $dateTime. Returning 'N/A'.");
      return 'N/A';
    }
    try {
      return DateFormat(pattern).format(dateTime);
    } catch (e) {
      if (kDebugMode)
        print(
            "DateFormatter: Error formatting date $dateTime with pattern $pattern: $e");
      return 'Invalid Date';
    }
  }
}

// Helper for parsing in the model (kept separate for clarity or can be moved into model file)
// This version is robust for ISO 8601 formats.
DateTime? parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty || dateStr == "0001-01-01T00:00:00Z") {
    return null; // Explicitly handle common null/default representations
  }
  try {
    // Attempt parsing standard ISO format
    DateTime parsed = DateTime.parse(dateStr);
    // Sanity check for very old dates (often indicates default/error)
    if (parsed.year < 1900) {
      // Adjust threshold if needed
      if (kDebugMode)
        print(
            "Warning: Parsed suspiciously old date: $dateStr. Treating as null.");
      return null;
    }
    return parsed.toLocal(); // Convert to local time zone for app consistency
  } catch (e) {
    if (kDebugMode)
      print(
          "Error parsing date string with DateTime.parse: '$dateStr'. Error: $e");
    // Optionally add fallback formats here if backend might send non-ISO dates
    // try {
    //    DateTime parsedFallback = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateStr, true).toLocal();
    //     if (parsedFallback.year < 1900) return null;
    //     return parsedFallback;
    // } catch (e2) { /* log fallback error */ }
    return null; // Return null if parsing fails
  }
}
