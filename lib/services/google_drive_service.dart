import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // Use the shared GoogleSignIn instance
  late final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Folder names in Drive
  static const String _folderName = 'Fihirana Recordings';
  static const String _privateFolderName = 'Private Recordings';
  static const String _publicFolderName = 'Public Recordings';
  String? _folderId;
  String? _privateFolderId;
  String? _publicFolderId;

  // Initialize with the shared GoogleSignIn instance
  void initialize(GoogleSignIn googleSignIn) {
    _googleSignIn = googleSignIn;
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      // First try to get current user without prompting
      _currentUser = _googleSignIn.currentUser;
      if (_currentUser != null) {
        await _initializeDriveApi();
        return _currentUser;
      }
      
      // If no current user, try silent sign-in
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initializeDriveApi();
        return _currentUser;
      }
      
      // If still no user, prompt for sign-in with Drive scopes
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initializeDriveApi();
      }
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in to Google Drive: $e');
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
    _privateFolderId = null;
    _publicFolderId = null;
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

  Future<String?> _getOrCreateSubfolder(String subfolderName) async {
    if (_driveApi == null || _folderId == null) return null;

    try {
      // Check if subfolder exists
      final fileList = await _driveApi!.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$subfolderName' and '$_folderId' in parents and trashed = false",
        $fields: "files(id, name)",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      } else {
        // Create subfolder
        final folder = drive.File()
          ..name = subfolderName
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = [_folderId!];

        final createdFolder = await _driveApi!.files.create(folder);
        return createdFolder.id;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating subfolder $subfolderName: $e');
      }
      return null;
    }
  }

  Future<void> _ensureSubfoldersExist() async {
    _privateFolderId = await _getOrCreateSubfolder(_privateFolderName);
    _publicFolderId = await _getOrCreateSubfolder(_publicFolderName);
  }

  Future<String?> uploadFile(File file, String title,
      {String? description, bool isPublic = false}) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null || _folderId == null) return null;

    // Ensure subfolders exist
    await _ensureSubfoldersExist();

    // Choose folder based on isPublic flag
    final targetFolderId = isPublic ? _publicFolderId : _privateFolderId;
    if (targetFolderId == null) return null;

    try {
      final driveFile = drive.File()
        ..name = title
        ..parents = [targetFolderId]
        ..description = description;

      final media = drive.Media(file.openRead(), await file.length());
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, webViewLink',
      );

      // If public, set file permissions
      if (isPublic && result.id != null) {
        await setFilePublic(result.id!);
      }

      return result.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading file to Drive: $e');
      }
      return null;
    }
  }

  Future<bool> setFilePublic(String fileId) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return false;

    try {
      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';

      await _driveApi!.permissions.create(permission, fileId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting file public: $e');
      }
      return false;
    }
  }

  Future<String?> getPublicLink(String fileId) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return null;

    try {
      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'webContentLink, webViewLink',
      ) as drive.File;

      // Return direct download link if available, otherwise view link
      return file.webContentLink ?? file.webViewLink;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting public link: $e');
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
