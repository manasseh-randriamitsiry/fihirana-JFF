/// Application-wide string constants to eliminate hardcoded strings
class AppStrings {
  // Common Actions
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Info';

  // Navigation
  static const String home = 'Home';
  static const String settings = 'Settings';
  static const String profile = 'Profile';
  static const String favorites = 'Favorites';
  static const String history = 'History';
  static const String search = 'Search';

  // Status Messages
  static const String noData = 'No data available';
  static const String noResults = 'No results found';
  static const String connectionError = 'Connection error';
  static const String serverError = 'Server error';
  static const String timeoutError = 'Request timeout';
  static const String unknownError = 'Unknown error occurred';

  // Validation Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Invalid email address';
  static const String invalidPhone = 'Invalid phone number';
  static const String passwordTooShort = 'Password too short';
  static const String passwordsDontMatch = 'Passwords don\'t match';

  // Permissions
  static const String cameraPermission = 'Camera permission required';
  static const String microphonePermission = 'Microphone permission required';
  static const String storagePermission = 'Storage permission required';
  static const String locationPermission = 'Location permission required';

  // File Operations
  static const String fileNotFound = 'File not found';
  static const String fileTooLarge = 'File too large';
  static const String invalidFileFormat = 'Invalid file format';
  static const String uploadFailed = 'Upload failed';
  static const String downloadFailed = 'Download failed';

  // Audio
  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String stop = 'Stop';
  static const String nextTrack = 'Next';
  static const String previousTrack = 'Previous';
  static const String shuffle = 'Shuffle';
  static const String repeat = 'Repeat';
  static const String volume = 'Volume';

  // Time
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String tomorrow = 'Tomorrow';
  static const String now = 'Now';
  static const String ago = 'ago';
  static const String justNow = 'Just now';

  // Units
  static const String seconds = 'seconds';
  static const String minutes = 'minutes';
  static const String hours = 'hours';
  static const String days = 'days';
  static const String weeks = 'weeks';
  static const String months = 'months';
  static const String years = 'years';

  // Sizes
  static const String bytes = 'B';
  static const String kilobytes = 'KB';
  static const String megabytes = 'MB';
  static const String gigabytes = 'GB';

  // Network
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String connecting = 'Connecting...';
  static const String connected = 'Connected';
  static const String disconnected = 'Disconnected';

  // Confirmation Messages
  static const String confirmDelete =
      'Are you sure you want to delete this item?';
  static const String confirmExit = 'Are you sure you want to exit?';
  static const String unsavedChanges =
      'You have unsaved changes. Do you want to save them?';

  // Empty States
  static const String noFavorites = 'No favorites yet';
  static const String noHistory = 'No history available';
  static const String noSearchResults = 'No search results';
  static const String emptyList = 'List is empty';

  // Helper methods
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes $bytes';
    if (bytes < 1024 * 1024)
      return '${(bytes / 1024).toStringAsFixed(1)} $kilobytes';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} $megabytes';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} $gigabytes';
  }
}
