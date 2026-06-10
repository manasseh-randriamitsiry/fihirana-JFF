import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/pages/splash_screen1.dart';
import 'package:fihirana/features/intro/presentation/pages/loading_screen.dart';
import 'package:fihirana/features/home/presentation/pages/home_screen.dart';
import 'package:fihirana/features/hymn/presentation/pages/create_hymn_page.dart';
import 'package:fihirana/features/hymn/presentation/pages/firebase_hymns_screen.dart';
import 'package:fihirana/features/bible/presentation/pages/bible_reader_screen.dart';
import 'package:fihirana/features/favorites/presentation/pages/favorites_screen.dart';
import 'package:fihirana/features/history/presentation/pages/history_screen.dart';
import 'package:fihirana/features/announcement/presentation/pages/announcement_screen.dart';
import 'package:fihirana/features/admin/presentation/pages/admin_panel_screen.dart';
import 'package:fihirana/features/home/presentation/pages/about_screen.dart';
import 'package:fihirana/features/playlist/presentation/pages/playlist_list_screen.dart';
import 'package:fihirana/features/recording/presentation/pages/recording_manager_screen.dart';
import 'package:fihirana/features/daily_verse/presentation/pages/daily_verse_settings_screen.dart';
import 'package:fihirana/features/settings/presentation/pages/settings_screen.dart';
import 'package:fihirana/features/contact/presentation/pages/contact_list_screen.dart';

/// Centralized route definitions for the application
class AppRouter {
  /// Get all application routes
  static List<GetPage> getPages() {
    return [
      GetPage(name: '/splash', page: () => const SplashScreen1()),
      GetPage(name: '/loading', page: () => const LoadingScreen()),
      GetPage(name: '/home', page: () => const HomeScreen()),
      GetPage(name: '/create_hymn', page: () => const CreateHymnPage()),
      GetPage(
        name: '/firebase_hymns',
        page: () => const FirebaseHymnsScreen(),
      ),
      GetPage(name: '/bible', page: () => const BibleReaderScreen()),
      GetPage(name: '/favorites', page: () => const FavoritesPage()),
      GetPage(name: '/history', page: () => const HistoryScreen()),
      GetPage(name: '/playlists', page: () => const PlaylistListScreen()),
      GetPage(
        name: '/recordings',
        page: () => const RecordingManagerScreen(),
      ),
      GetPage(
        name: '/daily_verse_settings',
        page: () => DailyVerseSettingsScreen(),
      ),
      GetPage(name: '/settings', page: () => const SettingsScreen()),
      GetPage(
        name: '/announcements',
        page: () => const AnnouncementScreen(),
      ),
      GetPage(name: '/admin', page: () => const AdminPanelScreen()),
      GetPage(name: '/about', page: () => const AboutScreen()),
      GetPage(name: '/contacts', page: () => const ContactListScreen()),
    ];
  }
}
