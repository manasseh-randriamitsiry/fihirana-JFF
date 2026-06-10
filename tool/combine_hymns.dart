#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main() async {
  final jsonDir = Directory('assets/json');
  if (!await jsonDir.exists()) {
    exit(1);
  }

  final jsonFiles = await jsonDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>()
      .toList();

  final Map<String, dynamic> combinedHymns = {
    'hymns': <Map<String, dynamic>>[],
    'total': jsonFiles.length,
    'generated_at': DateTime.now().toIso8601String(),
  };

  for (final file in jsonFiles) {
    try {
      final content = await file.readAsString();
      final jsonData = json.decode(content) as Map<String, dynamic>;

      // Add file path info for debugging
      jsonData['file_path'] = file.path.split(Platform.pathSeparator).last;

      combinedHymns['hymns'].add(jsonData);
    } catch (e) {
      return;
    }
  }

  // Write combined file
  final combinedFile = File('assets/hymns_combined.json');
  await combinedFile
      .writeAsString(const JsonEncoder.withIndent('  ').convert(combinedHymns));

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
    }
  }
}
