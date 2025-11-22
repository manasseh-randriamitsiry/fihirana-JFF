import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple script to verify that audio URLs are accessible
void main() async {
  
  // Test a few sample hymn IDs (using actual format from database)
  final testHymnIds = [
    '1',
    '10',
    '100',
    '50',
    '200',
  ];

  int failureCount = 0;
  
  for (final hymnId in testHymnIds) {
    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$hymnId.mp3';
    
    try {
      final response = await http.head(Uri.parse(audioUrl)).timeout(
        const Duration(seconds: 5),
      );
      
      if (response.statusCode == 200) {
      } else {
        failureCount++;
      }
    } catch (e) {
      failureCount++;
    }
  }
  
  exit(failureCount > 0 ? 1 : 0);
}
