#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('Generating asset manifest for JSON files...');
  
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
  
  // Create a manifest file that can be used at runtime
  final manifest = <String, String>{};
  for (final file in jsonFiles) {
    final relativePath = file.path.split(Platform.pathSeparator).join('/');
    final fileName = file.path.split(Platform.pathSeparator).last;
    final hymnId = fileName.replaceAll('.json', '');
    manifest[hymnId] = relativePath;
  }
  
  // Write manifest to assets
  final manifestFile = File('assets/hymn_manifest.json');
  await manifestFile.writeAsString(json.encode(manifest));
  
  print('Generated hymn manifest with ${manifest.length} entries');
  print('Manifest saved to: ${manifestFile.path}');
  
  // Update pubspec.yaml to include the manifest
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    String content = await pubspecFile.readAsString();
    
    if (!content.contains('assets/hymn_manifest.json')) {
      content = content.replaceFirst(
        '  assets:\n    # Add assets from images directory to the application.',
        '  assets:\n    # Add assets from images directory to the application.\n    - assets/hymn_manifest.json',
      );
      await pubspecFile.writeAsString(content);
      print('Updated pubspec.yaml to include hymn manifest');
    }
  }
  
  print('Asset generation completed successfully');
}