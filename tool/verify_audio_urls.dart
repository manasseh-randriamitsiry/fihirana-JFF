import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple script to verify that audio URLs are accessible
void main() async {
  print('Verifying audio URL accessibility...\n');
  
  // Test a few sample hymn IDs (using actual format from database)
  final testHymnIds = [
    '1',
    '10',
    '100',
    '50',
    '200',
  ];
  
  int successCount = 0;
  int failureCount = 0;
  
  for (final hymnId in testHymnIds) {
    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$hymnId.mp3';
    
    try {
      print('Checking $hymnId...');
      final response = await http.head(Uri.parse(audioUrl)).timeout(
        const Duration(seconds: 5),
      );
      
      if (response.statusCode == 200) {
        print('  ✓ $hymnId - Audio available (${response.statusCode})');
        successCount++;
      } else {
        print('  ✗ $hymnId - Not found (${response.statusCode})');
        failureCount++;
      }
    } catch (e) {
      print('  ✗ $hymnId - Error: $e');
      failureCount++;
    }
  }
  
  print('\n' + '=' * 50);
  print('Summary:');
  print('  Success: $successCount/${testHymnIds.length}');
  print('  Failed: $failureCount/${testHymnIds.length}');
  print('=' * 50);
  
  exit(failureCount > 0 ? 1 : 0);
}
