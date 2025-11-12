// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hymns App';

  @override
  String get home => 'Home';

  @override
  String get hymns => 'Hymns';

  @override
  String get favorites => 'Favorites';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get system => 'System';

  @override
  String get font => 'Font';

  @override
  String get color => 'Color';

  @override
  String get history => 'History';

  @override
  String get about => 'About';

  @override
  String get contact => 'Contact';

  @override
  String get privacy => 'Privacy Policy';

  @override
  String get terms => 'Terms of Service';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get feedback => 'Feedback';

  @override
  String get help => 'Help';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get send => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get select => 'Select';

  @override
  String get selected => 'Selected';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmDelete => 'Are you sure you want to delete this item?';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get noResults => 'No results found';

  @override
  String get searchHint => 'Search hymns, titles, or numbers...';

  @override
  String hymnNumber(int number) {
    return 'Hymn $number';
  }

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get shareHymn => 'Share hymn';

  @override
  String get copyHymn => 'Copy hymn';

  @override
  String get viewOriginal => 'View original';

  @override
  String get viewTranslation => 'View translation';

  @override
  String get hymnNotFound => 'Hymn not found';

  @override
  String get hymnNotAvailable => 'Hymn not available';

  @override
  String get downloadHymns => 'Download hymns';

  @override
  String get downloadingHymns => 'Downloading hymns...';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get downloadCanceled => 'Download canceled';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Update later';

  @override
  String get noUpdates => 'No updates available';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get version => 'Version';

  @override
  String get newVersionAvailable => 'A new version is available';

  @override
  String get pleaseUpdate => 'Please update to get the latest features';

  @override
  String get networkError => 'Network error';

  @override
  String get connectionError => 'Connection error';

  @override
  String get serverError => 'Server error';

  @override
  String get unknownError => 'Unknown error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get play => 'Play';

  @override
  String get alphabeticalOrder => 'Alphabetical order';

  @override
  String get numericalOrder => 'Numerical order';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filter => 'Filter';

  @override
  String get category => 'Category';

  @override
  String get categories => 'Categories';

  @override
  String get allCategories => 'All categories';

  @override
  String get book => 'Book';

  @override
  String get books => 'Books';

  @override
  String get selectCategory => 'Select category';

  @override
  String get selectBook => 'Select book';

  @override
  String get favoritesOnly => 'Favorites only';

  @override
  String get showFavorites => 'Show favorites';

  @override
  String get hideFavorites => 'Hide favorites';

  @override
  String get recentHymns => 'Recent hymns';

  @override
  String get mostViewed => 'Most viewed';

  @override
  String get randomHymn => 'Random hymn';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get relatedHymns => 'Related hymns';

  @override
  String get similarHymns => 'Similar hymns';

  @override
  String get hymnOfTheDay => 'Hymn of the day';

  @override
  String get dailyHymn => 'Daily hymn';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Read less';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get viewAll => 'View all';

  @override
  String get viewDetails => 'View details';

  @override
  String get details => 'Details';

  @override
  String get information => 'Information';

  @override
  String get aboutApp => 'About the app';

  @override
  String get appDescription => 'Hymns application with multilingual support';

  @override
  String get developedBy => 'Developed by';

  @override
  String get rightsReserved => 'All rights reserved';

  @override
  String get copyright => 'Copyright';

  @override
  String get license => 'License';

  @override
  String get openSource => 'Open source';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get contactUs => 'Contact us';

  @override
  String get support => 'Support';

  @override
  String get feedbackMessage => 'Your feedback is important to us';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get rateThisApp => 'Rate this app';

  @override
  String get shareWithFriends => 'Share with friends';

  @override
  String get tellAFriend => 'Tell a friend';

  @override
  String get invite => 'Invite';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get dataBackup => 'Data backup';

  @override
  String get backupData => 'Backup data';

  @override
  String get restoreData => 'Restore data';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data';

  @override
  String get dataExported => 'Data exported successfully';

  @override
  String get dataImported => 'Data imported successfully';

  @override
  String get backupCreated => 'Backup created successfully';

  @override
  String get backupRestored => 'Backup restored successfully';

  @override
  String get cannotCheckUpdates => 'Cannot check for updates';

  @override
  String get cannotRefresh => 'Cannot refresh';

  @override
  String get cannotSave => 'Cannot save';

  @override
  String get chooseFont => 'Choose a Font';

  @override
  String confirmDeleteHymn(String title) {
    return 'Are you sure you want to delete the hymn \"$title\"?';
  }

  @override
  String get copyHymnContent => 'Copy hymn content';

  @override
  String get deleteHymn => 'Delete hymn';

  @override
  String get deleteHymnContent => 'Delete selected hymn';

  @override
  String get deleteHymnError => 'Error deleting hymn';

  @override
  String get emptyHymnsList => 'No hymns available';

  @override
  String get emptyTitle => 'Empty title';

  @override
  String get errorLoadingNotes => 'Error loading notes';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get exitWithoutSaving => 'Exit without saving?';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get hymnDeleted => 'Hymn deleted';

  @override
  String hymnDetails(Object number, Object title) {
    return '$number - $title';
  }

  @override
  String get hymnSaved => 'Hymn saved';

  @override
  String get loginRequired => 'Please login first';

  @override
  String get noHymnsFound => 'No hymns found';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String refreshFailed(Object error) {
    return 'Failed to refresh: $error';
  }

  @override
  String get refreshSuccess => 'Refresh successful';

  @override
  String get saveChanges => 'Save changes';

  @override
  String searchError(Object error) {
    return 'Error: $error';
  }

  @override
  String get selectHymnFirst => 'Please select a hymn first';

  @override
  String get updateAvailableContent => 'There is a new version available. Would you like to download it?';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateFailed => 'Failed to update';

  @override
  String get updateFailedDownload => 'Failed to download update';

  @override
  String get updateFailedInstall => 'Failed to install update';

  @override
  String get updating => 'Updating...';

  @override
  String get userHymns => 'User Hymns';

  @override
  String get yesDelete => 'Yes, delete';

  @override
  String get noCancel => 'No, cancel';

  @override
  String get appTitleShort => 'JFF';

  @override
  String get checkUpdateError => 'Cannot check for updates';

  @override
  String errorOccurredMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get noHymnsAvailable => 'No hymns available';

  @override
  String get chorus => 'Chorus';

  @override
  String get verse => 'Verse';

  @override
  String verseWithNumber(int number) {
    return 'Verse $number';
  }

  @override
  String get bridge => 'Bridge';

  @override
  String get enterHymnNumber => 'Enter hymn number';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get verses => 'Verses';

  @override
  String get bridgeOptional => 'Bridge (Optional)';

  @override
  String get notes => 'Notes';

  @override
  String get submit => 'Submit';

  @override
  String get hymnSavedSuccessfully => 'Hymn saved successfully';

  @override
  String errorSavingHymn(String error) {
    return 'Error saving hymn: $error';
  }

  @override
  String get enterVerse => 'Enter verse';

  @override
  String noPermissionToCreate(String email) {
    return 'Hello $email,\nDue to specific reasons, you do not have permission to create hymns yet.\nPlease wait.\nOr contact the admin (manassé) for permission.';
  }

  @override
  String get createHymn => 'Create Hymn';

  @override
  String get addHymn => 'Add Hymn';

  @override
  String get number => 'Number';

  @override
  String get title => 'Title';

  @override
  String get hymnUpdatedSuccessfully => 'Hymn updated successfully';

  @override
  String errorUpdating(String error) {
    return 'Error: $error';
  }

  @override
  String get editNote => 'Edit Note';

  @override
  String get myPersonalNote => 'My Personal Note';

  @override
  String get noteInstructions => 'Enter your note about the hymn, such as chords, prayer reminders, or other information.';

  @override
  String get enterYourNote => 'Write your note here...';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get deleteNoteConfirm => 'Delete note?';

  @override
  String get deleteNoteMessage => 'Are you really sure you want to delete the note?';

  @override
  String get leave => 'Leave';

  @override
  String get signIn => 'Sign In';

  @override
  String get additionalHymns => 'Additional Hymns';

  @override
  String errorOccurredColon(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get noAdditionalHymns => 'No additional hymns';

  @override
  String get welcome => 'Welcome';

  @override
  String get signedInSuccessfully => 'You have signed in successfully.';

  @override
  String get favoriteHymns => 'Favorite Hymns';

  @override
  String get hymnHistory => 'Hymn History';

  @override
  String get changeColor => 'Change Color';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get announcements => 'Announcements';

  @override
  String get bible => 'Bible';

  @override
  String get signOut => 'Sign Out';

  @override
  String get aboutUs => 'About Us';

  @override
  String get cannotUpdate => 'Cannot update';

  @override
  String cannotDownload(String error) {
    return 'Cannot download: $error';
  }

  @override
  String get noPermissionAdmin => 'You do not have permission to access the admin panel';

  @override
  String get allSelectedHymnsDeleted => 'All selected hymns have been deleted';

  @override
  String get problem => 'Problem';

  @override
  String get enterNamePlease => 'Please enter a name';

  @override
  String get nameNotSaved => 'Name not saved';

  @override
  String get searchHymns => 'Search hymns...';

  @override
  String get syncInformation => 'Sync Information';

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get notLoggedInMessage => 'You are not logged in. Sign in to your account to access all features.';

  @override
  String get clearAllHistory => 'Clear all history';

  @override
  String get removeAllHistory => 'Remove all your history';

  @override
  String createdBy(String name) {
    return 'Created by';
  }

  @override
  String deleteFailed(String error) {
    return 'Delete failed';
  }

  @override
  String get sortByRecent => 'Recent';

  @override
  String get sortByOldest => 'Oldest';

  @override
  String get sortByNumber => 'Number';

  @override
  String get everyVerseChorus => 'Chorus:';

  @override
  String get checkingForUpdates => 'Checking for updates...';

  @override
  String get downloadAndInstall => 'Download & Install';

  @override
  String get downloading => 'Download...';

  @override
  String get download => 'Download';

  @override
  String get deleteHymnQuestion => 'Delete hymn?';

  @override
  String get deleteHymnFailed => 'Failed to delete.';

  @override
  String get hymnDeletedSuccess => 'Hymn deleted';

  @override
  String get errorCheckingUpdate => 'Failed to check for updates';

  @override
  String get errorDownloadingUpdate => 'Failed to download update';

  @override
  String get noAdminPermission => 'You do not have permission to access the admin panel';

  @override
  String get selectedHymnsDeleted => 'Selected hymns have been deleted';

  @override
  String get noHymns => 'No hymns';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get date => 'Date';

  @override
  String get errorLabel => 'Error';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get noPermission => 'No permission';

  @override
  String get userManagement => 'User Management';

  @override
  String get noEmail => 'No email';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get noUsers => 'No users';

  @override
  String get lastLogin => 'Last login';

  @override
  String get registered => 'Registered';

  @override
  String hymnCount(int count) {
    return '$count hymns';
  }

  @override
  String get sortBySongs => 'By number of songs';

  @override
  String get typeYesToConfirm => 'Type \"yes\" to confirm deletion';

  @override
  String get downloading2 => 'Downloading...';

  @override
  String get errorCheckingUpdates => 'Failed to check for updates';

  @override
  String get errorDownloadingUpdate2 => 'Failed to download';

  @override
  String get errorInstallingUpdate => 'Failed to install update';

  @override
  String get installUpdateTitle => 'Install update';

  @override
  String get installUpdateContent => 'Do you really want to install the new version? This will download the file and install it automatically.';

  @override
  String get install => 'Install';

  @override
  String get downloading3 => 'Downloading...';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get cancel2 => 'Cancel';

  @override
  String get createAnnouncement => 'Create announcement';

  @override
  String get message => 'Message';

  @override
  String get expirationDate => 'Expiration date';

  @override
  String get noDate => 'No date';

  @override
  String get create => 'Create';

  @override
  String get editAnnouncement => 'Edit announcement';

  @override
  String get update => 'Update';

  @override
  String get noExpirationDate => 'No expiration date';

  @override
  String get loadingBooks => 'Loading books...';

  @override
  String loadingChapter(Object book, Object chapter) {
    return 'Loading chapter $chapter from $book...';
  }

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get errorSavingSettings => 'Error saving settings';

  @override
  String get deleteHistorySuccess => 'Selected history deleted';

  @override
  String get deleteHistoryError => 'Error deleting history';

  @override
  String get clearHistorySuccess => 'History cleared';

  @override
  String get clearHistoryError => 'Error clearing history';

  @override
  String get cannotAddHymns => 'Cannot add hymns at this time';

  @override
  String get searchBooks => 'Search books...';

  @override
  String searchCurrentChapter(Object chapter) {
    return 'Search in chapter $chapter';
  }

  @override
  String get searchEntireBible => 'Search entire Bible';

  @override
  String get change => 'Change';

  @override
  String get bibleReader => 'Bible Reader';

  @override
  String emailLabel(Object email) {
    return 'Email: $email';
  }
}
