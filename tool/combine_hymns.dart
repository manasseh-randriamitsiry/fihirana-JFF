#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('Combining hymn JSON files into a single file...');
  
  final jsonDir = Directory('assets/json');
  if (!await jsonDir.exists()) {
    print('Error: assets/json directory not found');
    exit(1);
  }
  
  final jsonFiles = await jsonDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>()
      .toList();
  
  print('Found ${jsonFiles.length} JSON files');
  
  final Map<String, dynamic> combinedHymns = {
    'hymns': <Map<String, dynamic>>[],
    'total': jsonFiles.length,
    'generated_at': DateTime.now().toIso8601String(),
  };
  
  int successCount = 0;
  int failureCount = 0;
  
  for (final file in jsonFiles) {
    try {
      final content = await file.readAsString();
      final jsonData = json.decode(content) as Map<String, dynamic>;
      
      // Add file path info for debugging
      jsonData['file_path'] = file.path.split(Platform.pathSeparator).last;
      
      combinedHymns['hymns'].add(jsonData);
      successCount++;
      
      if (successCount <= 5) {
        print('Processed: ${file.path.split(Platform.pathSeparator).last}');
      }
    } catch (e) {
      failureCount++;
      print('Failed to process ${file.path}: $e');
    }
  }
  
  // Write combined file
  final combinedFile = File('assets/hymns_combined.json');
  await combinedFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(combinedHymns)
  );
  
  print('Combined hymn data saved to: ${combinedFile.path}');
  print('Successfully combined: $successCount hymns');
  print('Failed: $failureCount hymns');
  print('Total hymns in combined file: ${combinedHymns['hymns'].length}');
  
  // Update pubspec.yaml to include the combined file
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    String content = await pubspecFile.readAsString();
    
    if (!content.contains('assets/hymns_combined.json')) {
      content = content.replaceFirst(
        '    - assets/hymn_manifest.json',
        '    - assets/hymn_manifest.json\n    - assets/hymns_combined.json',
      );
      await pubspecFile.writeAsString(content);
      print('Updated pubspec.yaml to include combined hymn file');
    }
  }
  
  print('Hymn combination completed successfully');
}