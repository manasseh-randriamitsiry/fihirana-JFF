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

  /// No description provided for @errorUpdatingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorites'**
  String get errorUpdatingFavorites;

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

  /// No description provided for @newHymn.
  ///
  /// In en, this message translates to:
  /// **'New Hymn'**
  String get newHymn;

  /// No description provided for @deleteVerse.
  ///
  /// In en, this message translates to:
  /// **'Delete verse'**
  String get deleteVerse;

  /// No description provided for @addVerse.
  ///
  /// In en, this message translates to:
  /// **'Add Verse'**
  String get addVerse;

  /// No description provided for @hymnHint.
  ///
  /// In en, this message translates to:
  /// **'Hymn hint'**
  String get hymnHint;

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

  /// No description provided for @hymnAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Hymn already downloaded'**
  String get hymnAlreadyDownloaded;

  /// No description provided for @playlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFound;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @hymnNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Hymn not downloaded'**
  String get hymnNotDownloaded;

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
  /// **'A new update is available. Would you like to install it?'**
  String get updateAvailableContent;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
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
  /// **'About'**
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
  /// **'Delete failed: {error}'**
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
  /// **'You do not have permission'**
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
  /// **'Unknown'**
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
  /// **'Search Books'**
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
  String emailLabel(String email);

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get addressLabel;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

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
  String selectedItems(int count);

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
  /// **'Hymns of Jesosy Famonjena Fahamarinantsika\'s Church'**
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

  /// No description provided for @dailyBibleVerse.
  ///
  /// In en, this message translates to:
  /// **'Daily Bible Verse'**
  String get dailyBibleVerse;

  /// No description provided for @dailyInspiration.
  ///
  /// In en, this message translates to:
  /// **'Daily Inspiration'**
  String get dailyInspiration;

  /// No description provided for @receiveVerseEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Receive a Bible verse every day'**
  String get receiveVerseEveryDay;

  /// No description provided for @enableDailyVerse.
  ///
  /// In en, this message translates to:
  /// **'Enable Daily Verse'**
  String get enableDailyVerse;

  /// No description provided for @youWillReceiveDailyNotifications.
  ///
  /// In en, this message translates to:
  /// **'You will receive daily notifications'**
  String get youWillReceiveDailyNotifications;

  /// No description provided for @turnOnToReceiveDailyVerses.
  ///
  /// In en, this message translates to:
  /// **'Turn on to receive daily verses'**
  String get turnOnToReceiveDailyVerses;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationTime;

  /// No description provided for @todaysVerse.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Verse'**
  String get todaysVerse;

  /// No description provided for @noVerseAvailable.
  ///
  /// In en, this message translates to:
  /// **'No verse available'**
  String get noVerseAvailable;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get testNotificationSent;

  /// No description provided for @myPlaylists.
  ///
  /// In en, this message translates to:
  /// **'My Playlists'**
  String get myPlaylists;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// No description provided for @createFirstPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create your first playlist'**
  String get createFirstPlaylist;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get addToPlaylist;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @clearExpired.
  ///
  /// In en, this message translates to:
  /// **'Clear Expired'**
  String get clearExpired;

  /// No description provided for @clearAllCache.
  ///
  /// In en, this message translates to:
  /// **'Clear All Cache'**
  String get clearAllCache;

  /// No description provided for @clearCacheWarning.
  ///
  /// In en, this message translates to:
  /// **'This will remove all cached audio availability data. The app will need to check audio availability again.'**
  String get clearCacheWarning;

  /// No description provided for @allCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'All cache cleared'**
  String get allCacheCleared;

  /// No description provided for @expiredCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Expired cache cleared'**
  String get expiredCacheCleared;

  /// No description provided for @couldNotLaunchGoogleFonts.
  ///
  /// In en, this message translates to:
  /// **'Could not launch Google Fonts'**
  String get couldNotLaunchGoogleFonts;

  /// No description provided for @getFonts.
  ///
  /// In en, this message translates to:
  /// **'Get Fonts'**
  String get getFonts;

  /// No description provided for @errorPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String errorPlayingAudio(String error);

  /// No description provided for @playlistExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Sunday Service'**
  String get playlistExampleHint;

  /// No description provided for @confirmDeletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{playlistTitle}\"?'**
  String confirmDeletePlaylist(String playlistTitle);

  /// No description provided for @searchFavoriteSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Search for favorite songs...'**
  String get searchFavoriteSongsHint;

  /// No description provided for @searchWordsOrVersesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for words or verses...'**
  String get searchWordsOrVersesHint;

  /// No description provided for @wholeBible.
  ///
  /// In en, this message translates to:
  /// **'Whole Bible'**
  String get wholeBible;

  /// No description provided for @audioPlayer.
  ///
  /// In en, this message translates to:
  /// **'Audio Player'**
  String get audioPlayer;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get playAudio;

  /// No description provided for @audioCacheManagement.
  ///
  /// In en, this message translates to:
  /// **'Audio Cache Management'**
  String get audioCacheManagement;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @audioCache.
  ///
  /// In en, this message translates to:
  /// **'Audio Cache'**
  String get audioCache;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @noHymnsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No hymns added yet'**
  String get noHymnsAddedYet;

  /// No description provided for @errorLoadingHymns.
  ///
  /// In en, this message translates to:
  /// **'Error loading hymns'**
  String get errorLoadingHymns;

  /// No description provided for @audioAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio available'**
  String get audioAvailable;

  /// No description provided for @noAudioAvailable.
  ///
  /// In en, this message translates to:
  /// **'No audio available'**
  String get noAudioAvailable;

  /// No description provided for @searchBible.
  ///
  /// In en, this message translates to:
  /// **'Bible search'**
  String get searchBible;

  /// No description provided for @enterWordToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter word to search'**
  String get enterWordToSearch;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// No description provided for @changeWordToSearch.
  ///
  /// In en, this message translates to:
  /// **'Change word to search'**
  String get changeWordToSearch;

  /// A message that shows the number of hymns in a playlist
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No hymns} =1{1 hymn} other{{count} hymns}}'**
  String hymnsCount(int count);

  /// No description provided for @noChaptersFound.
  ///
  /// In en, this message translates to:
  /// **'No chapters found'**
  String get noChaptersFound;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username: {username}'**
  String usernameLabel(String username);

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {userId}'**
  String userIdLabel(String userId);

  /// No description provided for @syncInfoMessage1.
  ///
  /// In en, this message translates to:
  /// **'Your favorite hymns and history are saved to your Google account.'**
  String get syncInfoMessage1;

  /// No description provided for @syncInfoMessage2.
  ///
  /// In en, this message translates to:
  /// **'This will not be lost if you change accounts.'**
  String get syncInfoMessage2;

  /// No description provided for @errorOccurredWithDetails.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurredWithDetails(String error);

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @totalCachedHymns.
  ///
  /// In en, this message translates to:
  /// **'Total cached hymns: {count}'**
  String totalCachedHymns(int count);

  /// No description provided for @withAudio.
  ///
  /// In en, this message translates to:
  /// **'With audio: {count}'**
  String withAudio(int count);

  /// No description provided for @withoutAudio.
  ///
  /// In en, this message translates to:
  /// **'Without audio: {count}'**
  String withoutAudio(int count);

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get latestVersion;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @appIsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Your app is up to date'**
  String get appIsUpToDate;

  /// No description provided for @recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get recordings;

  /// No description provided for @refreshRecordings.
  ///
  /// In en, this message translates to:
  /// **'Refresh recordings'**
  String get refreshRecordings;

  /// No description provided for @syncFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync from Google Drive'**
  String get syncFromGoogleDrive;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @signInToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Google Drive'**
  String get signInToGoogleDrive;

  /// No description provided for @noRecordingsYet.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noRecordingsYet;

  /// No description provided for @startRecordingYourFavoriteHymns.
  ///
  /// In en, this message translates to:
  /// **'Start recording your favorite hymns'**
  String get startRecordingYourFavoriteHymns;

  /// No description provided for @personalRecordings.
  ///
  /// In en, this message translates to:
  /// **'Personal Recordings'**
  String get personalRecordings;

  /// No description provided for @publicRecordings.
  ///
  /// In en, this message translates to:
  /// **'Public Recordings'**
  String get publicRecordings;

  /// No description provided for @recordingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recording{count,plural, =1{} other{s}}'**
  String recordingCount(int count);

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @signedInAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in as:'**
  String get signedInAsLabel;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @hymnDuration.
  ///
  /// In en, this message translates to:
  /// **'Hymn {hymnId} • {duration}'**
  String hymnDuration(String hymnId, String duration);

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @uploadToDrive.
  ///
  /// In en, this message translates to:
  /// **'Upload to Drive'**
  String get uploadToDrive;

  /// No description provided for @uploadFailedTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Tap to retry.\nError: {error}'**
  String uploadFailedTapToRetry(String error);

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get deleteRecording;

  /// No description provided for @deleteRecordingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteRecordingConfirmation(String title);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @recordingDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Recording deleted successfully'**
  String get recordingDeletedSuccessfully;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get downloadStarted;

  /// No description provided for @recordingInProgressDialog.
  ///
  /// In en, this message translates to:
  /// **'Recording in progress'**
  String get recordingInProgressDialog;

  /// No description provided for @pleaseStopRecordingBeforePlaying.
  ///
  /// In en, this message translates to:
  /// **'Please stop recording before playing.'**
  String get pleaseStopRecordingBeforePlaying;

  /// No description provided for @stopAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Stop & Play'**
  String get stopAndPlay;

  /// No description provided for @recordingSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Recording session active'**
  String get recordingSessionActive;

  /// No description provided for @pleaseCloseRecordingOverlayFirst.
  ///
  /// In en, this message translates to:
  /// **'Please close the recording overlay first.'**
  String get pleaseCloseRecordingOverlayFirst;

  /// No description provided for @recordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording in progress...'**
  String get recordingInProgress;

  /// No description provided for @recordingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recording completed'**
  String get recordingCompleted;

  /// No description provided for @recordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved successfully'**
  String get recordingSaved;

  /// No description provided for @failedToSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to save recording: {error}'**
  String failedToSaveRecording(String error);

  /// No description provided for @failedToPlayRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to play recording'**
  String get failedToPlayRecording;

  /// No description provided for @recordingUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recording uploaded to Drive successfully'**
  String get recordingUploadSuccess;

  /// No description provided for @recordingUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get recordingUploadFailed;

  /// No description provided for @failedToUploadRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload recording: {error}'**
  String failedToUploadRecording(String error);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// No description provided for @failedToSyncFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync recordings from Drive: {error}'**
  String failedToSyncFromDrive(String error);

  /// No description provided for @driveSyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Drive sync completed'**
  String get driveSyncCompleted;

  /// No description provided for @driveSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Drive sign-in failed: {error}'**
  String driveSignInFailed(Object error);

  /// No description provided for @driveFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recording file not found'**
  String get driveFileNotFound;

  /// No description provided for @uploadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Upload in progress...'**
  String get uploadInProgress;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// No description provided for @totalStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Total storage used: {size}'**
  String totalStorageUsed(String size);

  /// No description provided for @recordingOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording Hymn {hymnId}'**
  String recordingOverlayTitle(String hymnId);

  /// No description provided for @minimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimize;

  /// No description provided for @recordingPaused.
  ///
  /// In en, this message translates to:
  /// **'Recording paused'**
  String get recordingPaused;

  /// No description provided for @recordingResumed.
  ///
  /// In en, this message translates to:
  /// **'Recording resumed'**
  String get recordingResumed;

  /// No description provided for @recordingStopped.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped'**
  String get recordingStopped;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @normalSpeed.
  ///
  /// In en, this message translates to:
  /// **'Normal Speed'**
  String get normalSpeed;

  /// No description provided for @renameRecording.
  ///
  /// In en, this message translates to:
  /// **'Rename Recording'**
  String get renameRecording;

  /// No description provided for @enterNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter new title'**
  String get enterNewTitle;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @recordingRenamed.
  ///
  /// In en, this message translates to:
  /// **'Recording renamed successfully'**
  String get recordingRenamed;

  /// No description provided for @failedToRenameRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename recording: {error}'**
  String failedToRenameRecording(String error);

  /// No description provided for @recordingManager.
  ///
  /// In en, this message translates to:
  /// **'Recording Manager'**
  String get recordingManager;

  /// No description provided for @createNewRecording.
  ///
  /// In en, this message translates to:
  /// **'Create New Recording'**
  String get createNewRecording;

  /// No description provided for @viewRecordings.
  ///
  /// In en, this message translates to:
  /// **'View Recordings'**
  String get viewRecordings;

  /// No description provided for @recordingPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Recording permission required'**
  String get recordingPermissionRequired;

  /// No description provided for @pleaseGrantMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Please grant microphone permission to record hymns.'**
  String get pleaseGrantMicrophonePermission;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @recordingNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Recording not allowed'**
  String get recordingNotAllowed;

  /// No description provided for @microphoneAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access denied. Please enable it in settings to record hymns.'**
  String get microphoneAccessDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @recordingError.
  ///
  /// In en, this message translates to:
  /// **'Recording Error'**
  String get recordingError;

  /// No description provided for @anErrorOccurredDuringRecording.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during recording: {error}'**
  String anErrorOccurredDuringRecording(String error);

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback Error'**
  String get playbackError;

  /// No description provided for @anErrorOccurredDuringPlayback.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during playback: {error}'**
  String anErrorOccurredDuringPlayback(String error);

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInFailed;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @appFeature1.
  ///
  /// In en, this message translates to:
  /// **'Browse thousands of hymns'**
  String get appFeature1;

  /// No description provided for @appFeature2.
  ///
  /// In en, this message translates to:
  /// **'Record your own versions'**
  String get appFeature2;

  /// No description provided for @appFeature3.
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get appFeature3;

  /// No description provided for @appFeature4.
  ///
  /// In en, this message translates to:
  /// **'Share with community'**
  String get appFeature4;

  /// No description provided for @continueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as: {name}'**
  String continueAs(String name);

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;
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
