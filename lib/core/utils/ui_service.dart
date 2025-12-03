import 'package:flutter/widgets.dart';
import 'package:fihirana/shared/widgets/common/contact_snackbars.dart';
import 'package:fihirana/shared/widgets/common/maps_snackbars.dart';
import 'package:fihirana/shared/widgets/common/audio_snackbars.dart';
import 'package:fihirana/shared/widgets/common/auth_snackbars.dart';

/// Service to handle UI interactions from services
/// This provides a clean separation between business logic and UI
class UIService {
  // Private constructor to prevent instantiation
  UIService._();

  /// Show contact permission snackbar
  static void showContactPermissionSnackBar(BuildContext context) {
    if (context.mounted) {
      ContactPermissionSnackBar.show(context);
    }
  }

  /// Show no contacts snackbar
  static void showNoContactsSnackBar(BuildContext context) {
    if (context.mounted) {
      NoContactsSnackBar.show(context);
    }
  }

  /// Show contacts error snackbar
  static void showContactsErrorSnackBar(BuildContext context, String error) {
    if (context.mounted) {
      ContactsErrorSnackBar.show(context, error);
    }
  }

  /// Show maps error snackbar
  static void showMapsErrorSnackBar(BuildContext context, dynamic error) {
    if (context.mounted) {
      MapsErrorSnackBar.show(context, error);
    }
  }

  /// Show maps redirect snackbar
  static void showMapsRedirectSnackBar(BuildContext context) {
    if (context.mounted) {
      MapsRedirectSnackBar.show(context);
    }
  }

  /// Show audio downloading snackbar
  static void showAudioDownloadingSnackBar() {
    AudioSnackBar.showDownloading();
  }

  /// Show audio drive error snackbar
  static void showAudioDriveErrorSnackBar(String errorMessage) {
    AudioSnackBar.showDriveError(errorMessage);
  }

  /// Show audio playback error snackbar
  static void showAudioPlaybackErrorSnackBar(String errorMessage) {
    AudioSnackBar.showPlaybackError(errorMessage);
  }

  /// Show audio not available snackbar
  static void showAudioNotAvailableSnackBar() {
    AudioSnackBar.showAudioNotAvailable();
  }

  /// Show auth email already in use snackbar
  static void showAuthEmailAlreadyInUseSnackBar() {
    AuthSnackBar.showEmailAlreadyInUse();
  }

  /// Show auth invalid credentials snackbar
  static void showAuthInvalidCredentialsSnackBar() {
    AuthSnackBar.showInvalidCredentials();
  }
}
