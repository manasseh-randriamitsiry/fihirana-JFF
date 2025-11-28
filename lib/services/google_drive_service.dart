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
    if (kDebugMode) {
      print(
          'GoogleDriveService: Initialized with shared GoogleSignIn instance');
      print('GoogleDriveService: Scopes: ${googleSignIn.scopes}');
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      if (kDebugMode) {
        print('GoogleDriveService: Starting sign-in process...');
      }

      // First try to get current user without prompting
      _currentUser = _googleSignIn.currentUser;
      if (_currentUser != null) {
        if (kDebugMode) {
          print(
              'GoogleDriveService: Found current user: ${_currentUser!.email}');
        }
        await _initializeDriveApi();
        return _currentUser;
      }

      // If no current user, try silent sign-in
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        if (kDebugMode) {
          print(
              'GoogleDriveService: Silent sign-in successful: ${_currentUser!.email}');
        }
        await _initializeDriveApi();
        return _currentUser;
      }

      // If still no user, prompt for sign-in with Drive scopes
      if (kDebugMode) {
        print(
            'GoogleDriveService: No current user, attempting interactive sign-in...');
      }
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        if (kDebugMode) {
          print(
              'GoogleDriveService: Interactive sign-in successful: ${_currentUser!.email}');
        }
        await _initializeDriveApi();
      }
      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('GoogleDriveService: Error signing in to Google Drive: $e');
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
      if (kDebugMode) {
        print(
            'GoogleDriveService: Initializing Drive API for user: ${_currentUser!.email}');
      }
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient != null) {
        _driveApi = drive.DriveApi(httpClient);
        await _ensureFolderExists();
        if (kDebugMode) {
          print('GoogleDriveService: Drive API initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('GoogleDriveService: Failed to get authenticated client');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('GoogleDriveService: Error initializing Drive API: $e');
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
      // Ensure proper file extension
      String fileName = title;
      if (!fileName.toLowerCase().endsWith('.m4a') &&
          !fileName.toLowerCase().endsWith('.mp3')) {
        fileName += '.m4a'; // Default to .m4a for recordings
      }

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [targetFolderId]
        ..description = description
        ..mimeType = 'audio/m4a'; // Explicitly set MIME type for audio

      final media = drive.Media(
        file.openRead(),
        await file.length(),
        contentType: 'audio/m4a', // Ensure correct content type
      );

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, webViewLink, mimeType, size',
      );

      if (kDebugMode) {
        print(
            'GoogleDriveService: Uploaded file ${result.name} with MIME type ${result.mimeType}');
      }

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
      // First, make the file publicly readable
      final permission = drive.Permission()
        ..role = 'reader'
        ..type = 'anyone';

      await _driveApi!.permissions.create(permission, fileId);

      // Get the file to construct direct download URL
      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'id, name, mimeType',
      ) as drive.File;

      // Construct direct download URL for public access
      // Format: https://drive.google.com/uc?export=download&id=FILE_ID
      final directDownloadUrl =
          'https://drive.google.com/uc?export=download&id=${file.id}';

      if (kDebugMode) {
        print(
            'GoogleDriveService: Generated public download URL: $directDownloadUrl');
      }

      return directDownloadUrl;
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

  /// Get authenticated download URL for private recordings
  Future<String?> getAuthenticatedDownloadUrl(String fileId) async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return null;

    try {
      // Get file metadata
      final file = await _driveApi!.files.get(
        fileId,
        $fields: 'id, name, mimeType',
      ) as drive.File;

      // Construct authenticated download URL
      // This URL will work with the user's authentication tokens
      final authenticatedUrl =
          'https://drive.google.com/uc?export=download&id=${file.id}';

      if (kDebugMode) {
        print(
            'GoogleDriveService: Generated authenticated download URL: $authenticatedUrl');
      }

      return authenticatedUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting authenticated download URL: $e');
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
      // First get file metadata to check MIME type
      final fileMetadata = await _driveApi!.files.get(
        fileId,
        $fields: 'name, mimeType, size',
      ) as drive.File;

      if (kDebugMode) {
        print(
            'GoogleDriveService: Downloading file ${fileMetadata.name} with MIME type ${fileMetadata.mimeType}');
      }

      // Check if it's a Google Docs file (which can't be downloaded directly)
      if (fileMetadata.mimeType != null &&
          fileMetadata.mimeType!.startsWith('application/vnd.google-apps')) {
        if (kDebugMode) {
          print(
              'GoogleDriveService: Cannot download Google Docs file directly, need to export');
        }

        // Try to export as audio if possible, otherwise fail
        try {
          final exportMimeType = fileMetadata.mimeType!.contains('audio')
              ? fileMetadata.mimeType!
              : 'audio/mpeg';

          final media = await _driveApi!.files.export(
            fileId,
            exportMimeType,
          ) as drive.Media;

          final saveFile = File(savePath);
          await saveFile.parent.create(recursive: true);

          final List<int> dataStore = [];
          await for (final data in media.stream) {
            dataStore.addAll(data);
          }

          await saveFile.writeAsBytes(dataStore);
          return saveFile;
        } catch (exportError) {
          if (kDebugMode) {
            print('GoogleDriveService: Export failed: $exportError');
          }
          throw Exception(
              'File is stored as Google Docs format and cannot be downloaded as audio. Please re-upload the original audio file.');
        }
      }

      // For regular binary files, download directly
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

  Future<drive.AboutStorageQuota?> getStorageQuota() async {
    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return null;

    try {
      final about = await _driveApi!.about.get($fields: 'storageQuota');
      if (kDebugMode) {
        print(
            'GoogleDriveService: Storage quota - Limit: ${about.storageQuota?.limit}, Usage: ${about.storageQuota?.usage}');
      }
      return about.storageQuota;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting storage quota: $e');
      }
      return null;
    }
  }

  bool get isSignedIn => _currentUser != null;
  GoogleSignInAccount? get currentUser => _currentUser;
}
