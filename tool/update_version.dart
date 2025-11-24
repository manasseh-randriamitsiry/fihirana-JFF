// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart tool/update_version.dart <command>');
    print('Commands:');
    print('  sync          Sync version from pubspec.yaml to other files');
    print('  increment     Increment patch version in pubspec.yaml');
    print('  check-update  Check if update is needed (sync or increment)');
    exit(1);
  }

  final command = args[0];
  switch (command) {
    case 'sync':
      syncVersion();
      break;
    case 'increment':
      incrementVersion();
      break;
    case 'check-update':
      checkUpdate();
      break;
    default:
      print('Unknown command: $command');
      exit(1);
  }
}

void checkUpdate() {
  print('Checking for updates...');
  final pubspecVersion = getPubspecVersion();
  final latestTag = getLatestTag();

  print('Pubspec version: $pubspecVersion');
  print('Latest tag: ${latestTag ?? "None"}');

  if (latestTag == null) {
    print('No tags found. Using pubspec version.');
    syncVersion();
    return;
  }

  if (isNewer(pubspecVersion, latestTag)) {
    print(
        'Pubspec version is newer ($pubspecVersion > $latestTag). Syncing...');
    syncVersion();
  } else {
    print(
        'Pubspec version is not newer ($pubspecVersion <= $latestTag). Incrementing...');
    // We need to increment based on the TAG version to ensure we're moving forward,
    // just in case pubspec is behind.
    // But wait, if pubspec is behind, we should probably increment the TAG version
    // and update pubspec to that new version.

    // Actually, simpler: just increment the pubspec version (which might be old)
    // until it is greater than tag?
    // Or better: Take the latest tag, increment IT, and set pubspec to that.

    final newVersion = incrementPatchVersion(latestTag);
    print('New version will be: $newVersion');
    updatePubspecYaml(newVersion);
    syncVersion(); // sync the new version
  }
}

String? getLatestTag() {
  try {
    // Get all tags matching v*.*.*, sorted by version (descending), take the first one
    final result = Process.runSync(
        'git', ['tag', '--list', 'v[0-9]*.[0-9]*.[0-9]*', '--sort=-v:refname']);

    if (result.exitCode == 0) {
      final output = result.stdout.toString().trim();
      if (output.isEmpty) return null;

      // The output might contain multiple lines, take the first one
      final latest = output.split('\n').first.trim();
      return latest.replaceAll('v', '');
    }
  } catch (e) {
    print('Error getting latest tag: $e');
  }
  return null;
}

bool isNewer(String v1, String v2) {
  List<int> p1 = v1.split('+')[0].split('.').map(int.parse).toList();
  List<int> p2 = v2.split('+')[0].split('.').map(int.parse).toList();

  for (int i = 0; i < 3; i++) {
    int n1 = i < p1.length ? p1[i] : 0;
    int n2 = i < p2.length ? p2[i] : 0;
    if (n1 > n2) return true;
    if (n1 < n2) return false;
  }
  return false;
}

void syncVersion() {
  print('Syncing version...');
  final version = getPubspecVersion();
  print('Current version: $version');

  updateBuildGradle(version);
  updatePubspecService(version);

  print('Sync complete!');
}

void incrementVersion() {
  print('Incrementing version...');
  final currentVersion = getPubspecVersion();
  final newVersion = incrementPatchVersion(currentVersion);
  print('New version: $newVersion');

  updatePubspecYaml(newVersion);

  // Also sync the new version to other files
  updateBuildGradle(newVersion);
  updatePubspecService(newVersion);

  print('Increment complete!');
}

String getPubspecVersion() {
  final file = File('pubspec.yaml');
  final content = file.readAsStringSync();
  final regex = RegExp(r'version:\s+(\d+\.\d+\.\d+.*)');
  final match = regex.firstMatch(content);
  if (match == null) {
    throw Exception('Could not find version in pubspec.yaml');
  }
  return match.group(1)!.trim();
}

String incrementPatchVersion(String version) {
  // Handle potential build number (e.g., 1.0.9+1)
  final parts = version.split('+');
  final versionNumber = parts[0];
  // final buildNumber = parts.length > 1 ? parts[1] : null;

  final versionParts = versionNumber.split('.').map(int.parse).toList();
  if (versionParts.length != 3) {
    throw Exception('Invalid version format: $versionNumber');
  }

  versionParts[2]++; // Increment patch

  var newVersion = versionParts.join('.');

  // If there was a build number, we might want to increment it too or keep it
  // For now, let's just keep the version clean without build number for the tag/release
  // or if we want to keep it, we can append it back.
  // Usually for a new release we might want to reset or increment build number.
  // Let's just increment the patch version for now.

  return newVersion;
}

void updatePubspecYaml(String newVersion) {
  final file = File('pubspec.yaml');
  var content = file.readAsStringSync();

  // Update version
  content = content.replaceAll(
    RegExp(r'version:\s+\d+\.\d+\.\d+.*'),
    'version: $newVersion',
  );

  file.writeAsStringSync(content);
  print('Updated pubspec.yaml');
}

void updateBuildGradle(String version) {
  final file = File('android/app/build.gradle.kts');
  if (!file.existsSync()) {
    print('Warning: android/app/build.gradle.kts not found');
    return;
  }

  var content = file.readAsStringSync();

  // Update versionName
  content = content.replaceAll(
    RegExp(r'versionName\s*=\s*".*"'),
    'versionName = "$version"',
  );

  file.writeAsStringSync(content);
  print('Updated android/app/build.gradle.kts');
}

void updatePubspecService(String version) {
  final file = File('lib/services/pubspec_service.dart');
  if (!file.existsSync()) {
    print('Warning: lib/services/pubspec_service.dart not found');
    return;
  }

  var content = file.readAsStringSync();

  // Update fallback version
  // Looking for: _cachedVersion = '1.0.9';
  content = content.replaceAll(
    RegExp(r"_cachedVersion\s*=\s*'.*';"),
    "_cachedVersion = '$version';",
  );

  file.writeAsStringSync(content);
  print('Updated lib/services/pubspec_service.dart');
}
