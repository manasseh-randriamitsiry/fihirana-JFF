import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:collection/collection.dart';

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
      if (kDebugMode) {
        print('GoogleDriveService: Ensuring folder "$_folderName" exists...');
      }

      // Search for the folder, including trashed ones to see if we can restore or if we should create new
      // We prioritize non-trashed folders
      final fileList = await _driveApi!.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName'",
        $fields: "files(id, name, trashed)",
      );

      drive.File? targetFolder;

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Prefer non-trashed folder
        targetFolder =
            fileList.files!.firstWhereOrNull((f) => f.trashed == false);

        // If only trashed folders exist, we might want to create a new one or use the trashed one (restoring it)
        // For now, let's just create a new one if all are trashed, to avoid confusion
        if (targetFolder == null) {
          if (kDebugMode) {
            print(
                'GoogleDriveService: Found only trashed folders, creating new one...');
          }
        } else {
          if (kDebugMode) {
            print(
                'GoogleDriveService: Found existing folder ID: ${targetFolder.id}');
          }
        }
      }

      if (targetFolder != null) {
        _folderId = targetFolder.id;
      } else {
        if (kDebugMode) {
          print(
              'GoogleDriveService: Folder not found (or all trashed), creating new one...');
        }
        // Create folder
        final folder = drive.File()
          ..name = _folderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _folderId = createdFolder.id;
        if (kDebugMode) {
          print('GoogleDriveService: Created new folder ID: $_folderId');
        }
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
      // Ensure proper file extension and MIME type
      String fileName = title;
      String mimeType = 'audio/m4a'; // Default MIME type
      
      if (fileName.toLowerCase().endsWith('.mp3')) {
        mimeType = 'audio/mpeg';
      } else if (fileName.toLowerCase().endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (fileName.toLowerCase().endsWith('.m4a')) {
        mimeType = 'audio/m4a';
      } else {
        // Default to .m4a for recordings without extension
        fileName += '.m4a';
        mimeType = 'audio/m4a';
      }

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [targetFolderId]
        ..description = description
        ..mimeType = mimeType; // Set correct MIME type based on file extension

      final media = drive.Media(
        file.openRead(),
        await file.length(),
        contentType: mimeType, // Ensure correct content type
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
      // First verify file exists and is accessible
      if (kDebugMode) {
        print('GoogleDriveService: Verifying file accessibility for ID: $fileId');
      }
      
      final fileAccessMetadata = await _driveApi!.files.get(
        fileId,
        $fields: 'name, mimeType, size, trashed',
      ) as drive.File;
      
      if (fileAccessMetadata.trashed == true) {
        throw Exception('File is in trash and cannot be accessed');
      }
      
      if (fileAccessMetadata.size == null) {
        throw Exception('File size is unknown - file may be corrupted');
      }
      
      if (kDebugMode) {
        print('GoogleDriveService: File verified - Name: ${fileAccessMetadata.name}, Size: ${fileAccessMetadata.size}, MIME: ${fileAccessMetadata.mimeType}');
      }
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
      if (fileAccessMetadata.mimeType != null &&
          fileAccessMetadata.mimeType!.startsWith('application/vnd.google-apps')) {
        if (kDebugMode) {
          print(
              'GoogleDriveService: Cannot download Google Docs file directly, need to export');
        }

        // Try to export as audio if possible, otherwise fail
        try {
          String exportMimeType;
          if (fileAccessMetadata.mimeType!.contains('audio')) {
            exportMimeType = fileAccessMetadata.mimeType!;
          } else {
            // Default to MP3 for unknown audio formats
            exportMimeType = 'audio/mpeg';
          }
          
          if (kDebugMode) {
            print('GoogleDriveService: Exporting as MIME type: $exportMimeType');
          }

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
      int totalBytes = 0;
      
      try {
        await for (final data in file.stream) {
          dataStore.addAll(data);
          totalBytes += data.length;
          
          // Log progress for large files
          if (kDebugMode && totalBytes > 0 && totalBytes % (1024 * 100) == 0) {
            print('GoogleDriveService: Downloaded ${totalBytes ~/ 1024} KB...');
          }
        }
        
        if (kDebugMode) {
          print('GoogleDriveService: Download completed. Total bytes: $totalBytes');
          print('GoogleDriveService: Expected size: ${fileAccessMetadata.size}');
        }
        
        // Validate download was successful
        if (totalBytes == 0) {
          throw Exception('Downloaded file is empty (0 bytes). This may indicate a permission issue or file corruption.');
        }
        
        if (fileAccessMetadata.size != null && totalBytes != fileAccessMetadata.size) {
          if (kDebugMode) {
            print('GoogleDriveService: Warning - Size mismatch. Downloaded: $totalBytes, Expected: ${fileAccessMetadata.size}');
          }
          // Still try to use the file, but log the warning
        }
        
        await saveFile.writeAsBytes(dataStore);
        
        // Verify file was written correctly
        final writtenFile = File(savePath);
        if (await writtenFile.exists()) {
          final fileSize = await writtenFile.length();
          if (kDebugMode) {
            print('GoogleDriveService: File written successfully. Size on disk: $fileSize bytes');
          }
          
          if (fileSize == 0) {
            throw Exception('File was written but is empty (0 bytes). Download may have failed.');
          }
          
          return writtenFile;
        } else {
          throw Exception('Failed to write downloaded file to disk');
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('GoogleDriveService: Error during download stream processing: $e');
        }
        throw Exception('Download failed: $e');
      }
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
      if (kDebugMode) {
        print(
            'GoogleDriveService: Listing recordings from folder ID: $_folderId');
      }

      // Ensure subfolders exist and are initialized
      await _ensureSubfoldersExist();

      if (kDebugMode) {
        print('GoogleDriveService: Private folder ID: $_privateFolderId');
        print('GoogleDriveService: Public folder ID: $_publicFolderId');
      }

      // List files in the main folder and its subfolders
      // First, get the main folder content
      final mainFolderList = await _driveApi!.files.list(
        q: "'$_folderId' in parents and trashed = false and mimeType != 'application/vnd.google-apps.folder'",
        $fields:
            "files(id, name, description, webViewLink, webContentLink, createdTime, modifiedTime, size, mimeType)",
      );

      final allFiles = mainFolderList.files ?? [];

      if (kDebugMode) {
        print(
            'GoogleDriveService: Found ${allFiles.length} files in main folder');
      }

      // Also check subfolders (Private and Public)
      if (_privateFolderId != null) {
        final privateList = await _driveApi!.files.list(
          q: "'$_privateFolderId' in parents and trashed = false and mimeType != 'application/vnd.google-apps.folder'",
          $fields:
              "files(id, name, description, webViewLink, webContentLink, createdTime, modifiedTime, size, mimeType)",
        );
        if (privateList.files != null) {
          allFiles.addAll(privateList.files!);
          if (kDebugMode) {
            print(
                'GoogleDriveService: Found ${privateList.files!.length} files in Private Recordings');
          }
        }
      } else {
        if (kDebugMode) {
          print(
              'GoogleDriveService: WARNING - Private folder ID is null, skipping private recordings');
        }
      }

      if (_publicFolderId != null) {
        final publicList = await _driveApi!.files.list(
          q: "'$_publicFolderId' in parents and trashed = false and mimeType != 'application/vnd.google-apps.folder'",
          $fields:
              "files(id, name, description, webViewLink, webContentLink, createdTime, modifiedTime, size, mimeType)",
        );
        if (publicList.files != null) {
          allFiles.addAll(publicList.files!);
          if (kDebugMode) {
            print(
                'GoogleDriveService: Found ${publicList.files!.length} files in Public Recordings');
          }
        }
      } else {
        if (kDebugMode) {
          print(
              'GoogleDriveService: WARNING - Public folder ID is null, skipping public recordings');
        }
      }

      if (kDebugMode) {
        print('GoogleDriveService: Found ${allFiles.length} files total');
      }

      // Deduplicate files based on ID
      final uniqueFiles = <String, drive.File>{};
      for (final file in allFiles) {
        if (file.id != null) {
          uniqueFiles[file.id!] = file;
        }
      }

      return uniqueFiles.values.toList();
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
