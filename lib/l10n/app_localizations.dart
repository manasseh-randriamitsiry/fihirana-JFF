import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_mg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('mg')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hymns App'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @hymns.
  ///
  /// In en, this message translates to:
  /// **'Hymns'**
  String get hymns;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDelete;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search hymns, titles, or numbers...'**
  String get searchHint;

  /// Hymn number with placeholder
  ///
  /// In en, this message translates to:
  /// **'Hymn {number}'**
  String hymnNumber(int number);

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @shareHymn.
  ///
  /// In en, this message translates to:
  /// **'Share hymn'**
  String get shareHymn;

  /// No description provided for @copyHymn.
  ///
  /// In en, this message translates to:
  /// **'Copy hymn'**
  String get copyHymn;

  /// No description provided for @viewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View original'**
  String get viewOriginal;

  /// No description provided for @viewTranslation.
  ///
  /// In en, this message translates to:
  /// **'View translation'**
  String get viewTranslation;

  /// No description provided for @hymnNotFound.
  ///
  /// In en, this message translates to:
  /// **'Hymn not found'**
  String get hymnNotFound;

  /// No description provided for @hymnNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Hymn not available'**
  String get hymnNotAvailable;

  /// No description provided for @downloadHymns.
  ///
  /// In en, this message translates to:
  /// **'Download hymns'**
  String get downloadHymns;

  /// No description provided for @downloadingHymns.
  ///
  /// In en, this message translates to:
  /// **'Downloading hymns...'**
  String get downloadingHymns;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadCanceled.
  ///
  /// In en, this message translates to:
  /// **'Download canceled'**
  String get downloadCanceled;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Update later'**
  String get updateLater;

  /// No description provided for @noUpdates.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get noUpdates;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get newVersionAvailable;

  /// No description provided for @pleaseUpdate.
  ///
  /// In en, this message translates to:
  /// **'Please update to get the latest features'**
  String get pleaseUpdate;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @alphabeticalOrder.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical order'**
  String get alphabeticalOrder;

  /// No description provided for @numericalOrder.
  ///
  /// In en, this message translates to:
  /// **'Numerical order'**
  String get numericalOrder;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select book'**
  String get selectBook;

  /// No description provided for @favoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get favoritesOnly;

  /// No description provided for @showFavorites.
  ///
  /// In en, this message translates to:
  /// **'Show favorites'**
  String get showFavorites;

  /// No description provided for @hideFavorites.
  ///
  /// In en, this message translates to:
  /// **'Hide favorites'**
  String get hideFavorites;

  /// No description provided for @recentHymns.
  ///
  /// In en, this message translates to:
  /// **'Recent hymns'**
  String get recentHymns;

  /// No description provided for @mostViewed.
  ///
  /// In en, this message translates to:
  /// **'Most viewed'**
  String get mostViewed;

  /// No description provided for @randomHymn.
  ///
  /// In en, this message translates to:
  /// **'Random hymn'**
  String get randomHymn;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @relatedHymns.
  ///
  /// In en, this message translates to:
  /// **'Related hymns'**
  String get relatedHymns;

  /// No description provided for @similarHymns.
  ///
  /// In en, this message translates to:
  /// **'Similar hymns'**
  String get similarHymns;

  /// No description provided for @hymnOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Hymn of the day'**
  String get hymnOfTheDay;

  /// No description provided for @dailyHymn.
  ///
  /// In en, this message translates to:
  /// **'Daily hymn'**
  String get dailyHymn;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutApp;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Hymns application with multilingual support'**
  String get appDescription;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get developedBy;

  /// No description provided for @rightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get rightsReserved;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get copyright;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get openSource;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is important to us'**
  String get feedbackMessage;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @rateThisApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get rateThisApp;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get shareWithFriends;

  /// No description provided for @tellAFriend.
  ///
  /// In en, this message translates to:
  /// **'Tell a friend'**
  String get tellAFriend;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data backup'**
  String get dataBackup;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get backupData;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore data'**
  String get restoreData;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get dataExported;

  /// No description provided for @dataImported.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get dataImported;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get backupRestored;

  /// No description provided for @cannotCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Cannot check for updates'**
  String get cannotCheckUpdates;

  /// No description provided for @cannotRefresh.
  ///
  /// In en, this message translates to:
  /// **'Cannot refresh'**
  String get cannotRefresh;

  /// No description provided for @cannotSave.
  ///
  /// In en, this message translates to:
  /// **'Cannot save'**
  String get cannotSave;

  /// No description provided for @chooseFont.
  ///
  /// In en, this message translates to:
  /// **'Choose a Font'**
  String get chooseFont;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @searchHymnsHint.
  ///
  /// In en, this message translates to:
  /// **'Search hymns'**
  String get searchHymnsHint;

  /// No description provided for @chaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chaptersCount(Object count);

  /// No description provided for @chooseColorFor.
  ///
  /// In en, this message translates to:
  /// **'Choose color for {colorType}'**
  String chooseColorFor(String colorType);

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose color'**
  String get chooseColor;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @presetColors.
  ///
  /// In en, this message translates to:
  /// **'Preset colors'**
  String get presetColors;

  /// No description provided for @customColors.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get customColors;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColor;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColor;

  /// No description provided for @drawerColor.
  ///
  /// In en, this message translates to:
  /// **'Drawer color'**
  String get drawerColor;

  /// No description provided for @iconColor.
  ///
  /// In en, this message translates to:
  /// **'Icon color'**
  String get iconColor;

  /// No description provided for @chooseFontStyle.
  ///
  /// In en, this message translates to:
  /// **'Choose font style'**
  String get chooseFontStyle;

  /// No description provided for @sampleText.
  ///
  /// In en, this message translates to:
  /// **'Jesus Saves Our Souls'**
  String get sampleText;

  /// No description provided for @yesLowercase.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get yesLowercase;

  /// No description provided for @createdByLabel.
  ///
  /// In en, this message translates to:
  /// **'Created by: {name}{email}'**
  String createdByLabel(String name, String email);

  /// No description provided for @confirmDeleteHymn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the hymn \"{title}\"?'**
  String confirmDeleteHymn(String title);

  /// No description provided for @copyHymnContent.
  ///
  /// In en, this message translates to:
  /// **'Copy hymn content'**
  String get copyHymnContent;

  /// No description provided for @deleteHymn.
  ///
  /// In en, this message translates to:
  /// **'Delete hymn'**
  String get deleteHymn;

  /// No description provided for @deleteHymnContent.
  ///
  /// In en, this message translates to:
  /// **'Delete selected hymn'**
  String get deleteHymnContent;

  /// No description provided for @deleteHymnError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting hymn'**
  String get deleteHymnError;

  /// No description provided for @emptyHymnsList.
  ///
  /// In en, this message translates to:
  /// **'No hymns available'**
  String get emptyHymnsList;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty title'**
  String get emptyTitle;

  /// No description provided for @errorLoadingNotes.
  ///
  /// In en, this message translates to:
  /// **'Error loading notes'**
  String get errorLoadingNotes;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @exitWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Exit without saving?'**
  String get exitWithoutSaving;

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoriteRemoved;

  /// No description provided for @favoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoriteAdded;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @hymnDeleted.
  ///
  /// In en, this message translates to:
  /// **'Hymn deleted'**
  String get hymnDeleted;

  /// No description provided for @hymnDetails.
  ///
  /// In en, this message translates to:
  /// **'{number} - {title}'**
  String hymnDetails(Object number, Object title);

  /// No description provided for @hymnSaved.
  ///
  /// In en, this message translates to:
  /// **'Hymn saved'**
  String get hymnSaved;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get loginRequired;

  /// No description provided for @noHymnsFound.
  ///
  /// In en, this message translates to:
  /// **'No hymns found'**
  String get noHymnsFound;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh: {error}'**
  String refreshFailed(Object error);

  /// No description provided for @refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refresh successful'**
  String get refreshSuccess;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String searchError(Object error);

  /// No description provided for @selectHymnFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a hymn first'**
  String get selectHymnFirst;

  /// No description provided for @updateAvailableContent.
  ///
  /// In en, this message translates to:
  /// **'There is a new version available. Would you like to download it?'**
  String get updateAvailableContent;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get updateFailed;

  /// No description provided for @updateFailedDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update'**
  String get updateFailedDownload;

  /// No description provided for @updateFailedInstall.
  ///
  /// In en, this message translates to:
  /// **'Failed to install update'**
  String get updateFailedInstall;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @userHymns.
  ///
  /// In en, this message translates to:
  /// **'User Hymns'**
  String get userHymns;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get yesDelete;

  /// No description provided for @noCancel.
  ///
  /// In en, this message translates to:
  /// **'No, cancel'**
  String get noCancel;

  /// No description provided for @appTitleShort.
  ///
  /// In en, this message translates to:
  /// **'JFF'**
  String get appTitleShort;

  /// No description provided for @checkUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Cannot check for updates'**
  String get checkUpdateError;

  /// No description provided for @errorOccurredMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurredMessage(Object error);

  /// No description provided for @noHymnsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hymns available'**
  String get noHymnsAvailable;

  /// No description provided for @chorus.
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get chorus;

  /// No description provided for @verse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get verse;

  /// No description provided for @verseWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Verse {number}'**
  String verseWithNumber(int number);

  /// No description provided for @bridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get bridge;

  /// No description provided for @enterHymnNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter hymn number'**
  String get enterHymnNumber;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @verses.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get verses;

  /// No description provided for @bridgeOptional.
  ///
  /// In en, this message translates to:
  /// **'Bridge (Optional)'**
  String get bridgeOptional;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @hymnSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hymn saved successfully'**
  String get hymnSavedSuccessfully;

  /// No description provided for @errorSavingHymn.
  ///
  /// In en, this message translates to:
  /// **'Error saving hymn: {error}'**
  String errorSavingHymn(String error);

  /// No description provided for @enterVerse.
  ///
  /// In en, this message translates to:
  /// **'Enter verse'**
  String get enterVerse;

  /// No description provided for @noPermissionToCreate.
  ///
  /// In en, this message translates to:
  /// **'Hello {email},\nDue to specific reasons, you do not have permission to create hymns yet.\nPlease wait.\nOr contact the admin (manassé) for permission.'**
  String noPermissionToCreate(String email);

  /// No description provided for @createHymn.
  ///
  /// In en, this message translates to:
  /// **'Create Hymn'**
  String get createHymn;

  /// No description provided for @addHymn.
  ///
  /// In en, this message translates to:
  /// **'Add Hymn'**
  String get addHymn;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @hymnUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hymn updated successfully'**
  String get hymnUpdatedSuccessfully;

  /// No description provided for @errorUpdating.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorUpdating(String error);

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @myPersonalNote.
  ///
  /// In en, this message translates to:
  /// **'My Personal Note'**
  String get myPersonalNote;

  /// No description provided for @noteInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your note about the hymn, such as chords, prayer reminders, or other information.'**
  String get noteInstructions;

  /// No description provided for @enterYourNote.
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get enterYourNote;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNoteConfirm;

  /// No description provided for @deleteNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you really sure you want to delete the note?'**
  String get deleteNoteMessage;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @additionalHymns.
  ///
  /// In en, this message translates to:
  /// **'Additional Hymns'**
  String get additionalHymns;

  /// No description provided for @errorOccurredColon.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String errorOccurredColon(String error);

  /// No description provided for @noAdditionalHymns.
  ///
  /// In en, this message translates to:
  /// **'No additional hymns'**
  String get noAdditionalHymns;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'You have signed in successfully.'**
  String get signedInSuccessfully;

  /// No description provided for @favoriteHymns.
  ///
  /// In en, this message translates to:
  /// **'Favorite Hymns'**
  String get favoriteHymns;

  /// No description provided for @hymnHistory.
  ///
  /// In en, this message translates to:
  /// **'Hymn History'**
  String get hymnHistory;

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get changeColor;

  /// No description provided for @fontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontStyle;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @bible.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get bible;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @cannotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Cannot update'**
  String get cannotUpdate;

  /// No description provided for @cannotDownload.
  ///
  /// In en, this message translates to:
  /// **'Cannot download: {error}'**
  String cannotDownload(String error);

  /// No description provided for @noPermissionAdmin.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access the admin panel'**
  String get noPermissionAdmin;

  /// No description provided for @allSelectedHymnsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All selected hymns have been deleted'**
  String get allSelectedHymnsDeleted;

  /// No description provided for @problem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get problem;

  /// No description provided for @enterNamePlease.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get enterNamePlease;

  /// No description provided for @nameNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Name not saved'**
  String get nameNotSaved;

  /// No description provided for @searchHymns.
  ///
  /// In en, this message translates to:
  /// **'Search hymns...'**
  String get searchHymns;

  /// No description provided for @syncInformation.
  ///
  /// In en, this message translates to:
  /// **'Sync Information'**
  String get syncInformation;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// No description provided for @notLoggedInMessage.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in. Sign in to your account to access all features.'**
  String get notLoggedInMessage;

  /// No description provided for @clearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get clearAllHistory;

  /// No description provided for @removeAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove all your history'**
  String get removeAllHistory;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String createdBy(String name);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String deleteFailed(String error);

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortByRecent;

  /// No description provided for @sortByOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortByOldest;

  /// No description provided for @sortByNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get sortByNumber;

  /// No description provided for @everyVerseChorus.
  ///
  /// In en, this message translates to:
  /// **'Chorus:'**
  String get everyVerseChorus;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @downloadAndInstall.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get downloadAndInstall;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Download...'**
  String get downloading;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @deleteHymnQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete hymn?'**
  String get deleteHymnQuestion;

  /// No description provided for @deleteHymnFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete.'**
  String get deleteHymnFailed;

  /// No description provided for @hymnDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hymn deleted'**
  String get hymnDeletedSuccess;

  /// No description provided for @errorCheckingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get errorCheckingUpdate;

  /// No description provided for @errorDownloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update'**
  String get errorDownloadingUpdate;

  /// No description provided for @noAdminPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access the admin panel'**
  String get noAdminPermission;

  /// No description provided for @selectedHymnsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected hymns have been deleted'**
  String get selectedHymnsDeleted;

  /// No description provided for @noHymns.
  ///
  /// In en, this message translates to:
  /// **'No hymns'**
  String get noHymns;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission'**
  String get noPermission;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users'**
  String get noUsers;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get lastLogin;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @hymnCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hymns'**
  String hymnCount(int count);

  /// No description provided for @sortBySongs.
  ///
  /// In en, this message translates to:
  /// **'By number of songs'**
  String get sortBySongs;

  /// No description provided for @typeYesToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"yes\" to confirm deletion'**
  String get typeYesToConfirm;

  /// No description provided for @downloading2.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading2;

  /// No description provided for @errorCheckingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get errorCheckingUpdates;

  /// No description provided for @errorDownloadingUpdate2.
  ///
  /// In en, this message translates to:
  /// **'Failed to download'**
  String get errorDownloadingUpdate2;

  /// No description provided for @errorInstallingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to install update'**
  String get errorInstallingUpdate;

  /// No description provided for @installUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get installUpdateTitle;

  /// No description provided for @installUpdateContent.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to install the new version? This will download the file and install it automatically.'**
  String get installUpdateContent;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @downloading3.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading3;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @cancel2.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel2;

  /// No description provided for @createAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Create announcement'**
  String get createAnnouncement;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration date'**
  String get expirationDate;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @editAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Edit announcement'**
  String get editAnnouncement;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @noExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'No expiration date'**
  String get noExpirationDate;

  /// No description provided for @loadingBooks.
  ///
  /// In en, this message translates to:
  /// **'Loading books...'**
  String get loadingBooks;

  /// No description provided for @loadingChapter.
  ///
  /// In en, this message translates to:
  /// **'Loading chapter {chapter} from {book}...'**
  String loadingChapter(Object book, Object chapter);

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get errorSavingSettings;

  /// No description provided for @deleteHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Selected history deleted'**
  String get deleteHistorySuccess;

  /// No description provided for @deleteHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting history'**
  String get deleteHistoryError;

  /// No description provided for @clearHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get clearHistorySuccess;

  /// No description provided for @clearHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Error clearing history'**
  String get clearHistoryError;

  /// No description provided for @cannotAddHymns.
  ///
  /// In en, this message translates to:
  /// **'Cannot add hymns at this time'**
  String get cannotAddHymns;

  /// No description provided for @searchBooks.
  ///
  /// In en, this message translates to:
  /// **'Search books...'**
  String get searchBooks;

  /// No description provided for @searchCurrentChapter.
  ///
  /// In en, this message translates to:
  /// **'Search in chapter {chapter}'**
  String searchCurrentChapter(Object chapter);

  /// No description provided for @searchEntireBible.
  ///
  /// In en, this message translates to:
  /// **'Search entire Bible'**
  String get searchEntireBible;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @bibleReader.
  ///
  /// In en, this message translates to:
  /// **'Bible Reader'**
  String get bibleReader;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String emailLabel(Object email);

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get addressLabel;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(Object version);

  /// No description provided for @appNameSuffix.
  ///
  /// In en, this message translates to:
  /// **'JFF'**
  String get appNameSuffix;

  /// No description provided for @headquarters.
  ///
  /// In en, this message translates to:
  /// **'Headquarters:'**
  String get headquarters;

  /// No description provided for @headquartersAddress.
  ///
  /// In en, this message translates to:
  /// **'Antsororokavo Fianarantsoa 301'**
  String get headquartersAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'+261 34 29 439 71'**
  String get phoneNumber;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @clearAllHistoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get clearAllHistoryQuestion;

  /// No description provided for @historyCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'History cannot be undone once deleted.'**
  String get historyCannotBeUndone;

  /// No description provided for @deleteSelectedHistoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete selected history?'**
  String get deleteSelectedHistoryQuestion;

  /// No description provided for @selectedItems.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedItems(Object count);

  /// No description provided for @welcomeToHymnsApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hymns App'**
  String get welcomeToHymnsApp;

  /// No description provided for @praiseTheLord.
  ///
  /// In en, this message translates to:
  /// **'Praise the Lord for He is good'**
  String get praiseTheLord;

  /// No description provided for @hymnsApp.
  ///
  /// In en, this message translates to:
  /// **'Hymns App'**
  String get hymnsApp;

  /// No description provided for @aboutTheApp.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get aboutTheApp;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @feature1.
  ///
  /// In en, this message translates to:
  /// **'Hymns created for JFF church'**
  String get feature1;

  /// No description provided for @feature2.
  ///
  /// In en, this message translates to:
  /// **'Makes worship to God easier'**
  String get feature2;

  /// No description provided for @feature3.
  ///
  /// In en, this message translates to:
  /// **'You can add new hymns'**
  String get feature3;

  /// No description provided for @feature4.
  ///
  /// In en, this message translates to:
  /// **'Need Google account for additional features'**
  String get feature4;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @term1.
  ///
  /// In en, this message translates to:
  /// **'I will not use the application in a bad way'**
  String get term1;

  /// No description provided for @term2.
  ///
  /// In en, this message translates to:
  /// **'I will not add hymns that do not align with JFF worship'**
  String get term2;

  /// No description provided for @agreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms above'**
  String get agreement;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @splashScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Hymns of Jesus Savior of Our Souls'**
  String get splashScreenTitle;

  /// No description provided for @splashScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Praise the Lord for He is good'**
  String get splashScreenSubtitle;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept terms'**
  String get acceptTerms;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'mg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'mg': return AppLocalizationsMg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
