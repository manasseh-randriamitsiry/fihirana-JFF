// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/testing.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fihirana/services/version_check_service.dart';
// import 'package:fihirana/services/apk_download_service.dart';
// import 'package:fihirana/services/pubspec_service.dart';
//
// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   const MethodChannel channel =
//       MethodChannel('dev.fluttercommunity.plus/package_info');
//   const MethodChannel inAppUpdateChannel = MethodChannel('in_app_update');
//   const MethodChannel awesomeNotificationsChannel =
//       MethodChannel('awesome_notifications');
//
//   setUp(() {
//     // Mock Awesome Notifications
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(
//       awesomeNotificationsChannel,
//       (MethodCall methodCall) async {
//         return true; // Return success for all calls
//       },
//     );
//
//     // Mock Package Info
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(
//       channel,
//       (MethodCall methodCall) async {
//         if (methodCall.method == 'getAll') {
//           return {
//             'appName': 'Fihirana',
//             'packageName': 'com.manasseh.fihirana_jff',
//             'version': '1.0.9',
//             'buildNumber': '1',
//           };
//         }
//         return null;
//       },
//     );
//
//     // Mock InAppUpdate
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(
//       inAppUpdateChannel,
//       (MethodCall methodCall) async {
//         if (methodCall.method == 'checkForUpdate') {
//           // Simulate "No Update" from Play Store
//           return {
//             'updateAvailability': 1, // updateNotAvailable
//             'immediateUpdateAllowed': false,
//             'flexibleUpdateAllowed': false,
//             'availableVersionCode': 1,
//             'installStatus': 0,
//             'packageName': 'com.manasseh.fihirana_jff',
//             'clientVersionStalenessDays': 0,
//             'updatePriority': 0,
//           };
//         }
//         return null;
//       },
//     );
//
//     SharedPreferences.setMockInitialValues({});
//     PubspecService.setVersion('1.0.9');
//   });
//
//   tearDown(() {
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(channel, null);
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(inAppUpdateChannel, null);
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(awesomeNotificationsChannel, null);
//     VersionCheckService.client = null;
//     ApkDownloadService.mockDownloadHandler = null;
//   });
//
//   test(
//       'Should fallback to GitHub update when InAppUpdate fails but GitHub has new version',
//       () async {
//     // Arrange
//     bool updateAvailableCallbackCalled = false;
//     VersionCheckService.setOnUpdateAvailableCallback(() {
//       updateAvailableCallbackCalled = true;
//     });
//
//     // Mock GitHub Response (Newer version 1.0.10)
//     final mockClient = MockClient((request) async {
//       if (request.url.toString() == VersionCheckService.githubApiUrl) {
//         return http.Response(
//             json.encode({
//               'tag_name': 'v1.0.10',
//               'html_url': 'https://github.com/release',
//               'body': 'Release notes',
//               'assets': [
//                 {
//                   'name': 'app-universal-release.apk',
//                   'browser_download_url':
//                       'https://github.com/download/app-universal-release.apk'
//                 }
//               ]
//             }),
//             200);
//       }
//       return http.Response('Not Found', 404);
//     });
//     VersionCheckService.client = mockClient;
//
//     // Act
//     await VersionCheckService.checkForUpdate();
//
//     // Assert
//     expect(updateAvailableCallbackCalled, true);
//   });
//
//   test('Should download and install using ApkDownloadService', () async {
//     // Arrange
//     bool downloadCalled = false;
//     String? downloadedUrl;
//     String? downloadedVersion;
//
//     final mockClient = MockClient((request) async {
//       return http.Response(
//           json.encode({
//             'tag_name': 'v1.0.10',
//             'html_url': 'https://github.com/release',
//             'body': 'Release notes',
//             'assets': [
//               {
//                 'name': 'app-universal-release.apk',
//                 'browser_download_url':
//                     'https://github.com/download/app-universal-release.apk'
//               }
//             ]
//           }),
//           200);
//     });
//     VersionCheckService.client = mockClient;
//
//     // Run check to populate cache
//     await VersionCheckService.checkForUpdate();
//
//     // Now set the mock handler AFTER the check
//     ApkDownloadService.mockDownloadHandler = (url, version) async {
//       downloadCalled = true;
//       downloadedUrl = url;
//       downloadedVersion = version;
//     };
//
//     // Act
//     await VersionCheckService.downloadAndInstallLatestVersion();
//
//     // Assert
//     expect(downloadCalled, true,
//         reason: 'Download handler should have been called');
//     expect(
//         downloadedUrl, 'https://github.com/download/app-universal-release.apk',
//         reason: 'Should download the universal APK');
//     expect(downloadedVersion, '1.0.10', reason: 'Should use version 1.0.10');
//   });
// }
