import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Folder name in Drive
  static const String _folderName = 'Fihirana Recordings';
  String? _folderId;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initializeDriveApi();
      }
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in to Google: $e');
      }
      return null;
    }
  }

  // Method to automatically check for existing signed-in accounts
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initializeDriveApi();
        if (kDebugMode) {
          print(
              'GoogleDriveService: Silent sign-in successful for ${_currentUser!.email}');
        }
      } else {
        if (kDebugMode) {
          print('GoogleDriveService: No existing signed-in account found');
        }
      }
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error during silent sign-in: $e');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _folderId = null;
  }

  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) return;

    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient != null) {
        _driveApi = drive.DriveApi(httpClient);
        await _ensureFolderExists();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Drive API: $e');
      }
    }
  }

  Future<void> _ensureFolderExists() async {
    if (_driveApi == null) return;

    try {
      // Check if folder exists
      final fileList = await _driveApi!.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false",
        $fields: "files(id, name)",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _folderId = fileList.files!.first.id;
      } else {
        // Create folder
        final folder = drive.File()
          ..name = _folderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _folderId = createdFolder.id;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring Drive folder exists: $e');
      }
    }
  }

  Future<String?> uploadFile(File file, String title,
      {String? description}) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null || _folderId == null) return null;

    try {
      final driveFile = drive.File()
        ..name = title
        ..parents = [_folderId!]
        ..description = description;

      final media = drive.Media(file.openRead(), await file.length());
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, webViewLink',
      );

      return result.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading file to Drive: $e');
      }
      return null;
    }
  }

  Future<String?> getWebViewLink(String fileId) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return null;

    try {
      final file = await _driveApi!.files.get(fileId, $fields: 'webViewLink')
          as drive.File;
      return file.webViewLink;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting web view link: $e');
      }
      return null;
    }
  }

  Future<bool> deleteFile(String fileId) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return false;

    try {
      // Permanently delete the file (not just move to trash)
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file from Drive: $e');
      }
      return false;
    }
  }

  Future<File?> downloadFile(String fileId, String savePath) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return null;

    try {
      final drive.Media file = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final saveFile = File(savePath);
      // Ensure directory exists
      await saveFile.parent.create(recursive: true);

      final List<int> dataStore = [];
      await for (final data in file.stream) {
        dataStore.addAll(data);
      }

      await saveFile.writeAsBytes(dataStore);
      return saveFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading file from Drive: $e');
      }
      return null;
    }
  }

  Future<List<drive.File>> listRecordings() async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null || _folderId == null) return [];

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$_folderId' in parents and trashed = false",
        $fields:
            "files(id, name, description, webViewLink, createdTime, modifiedTime, size)",
      );

      return fileList.files ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('Error listing recordings from Drive: $e');
      }
      return [];
    }
  }

  bool get isSignedIn => _currentUser != null;
  GoogleSignInAccount? get currentUser => _currentUser;
}
