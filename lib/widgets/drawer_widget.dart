import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/theme_controller.dart';
import '../controller/color_controller.dart';
import '../screen/favorite/favorites_screen.dart';
import '../screen/admin/admin_panel_screen.dart';
import '../screen/about/about_screen.dart';
import '../screen/history/history_screen.dart';
import '../screen/announcement/announcement_screen.dart';
import '../screen/hymn/create_hymn_page.dart';
import '../screen/hymn/firebase_hymns_screen.dart';
import '../screen/bible/enhanced_bible_reader_screen.dart';
import '../services/audio_service.dart';
import 'color_picker_widget.dart';
import 'font_picker_widget.dart';
import '../l10n/app_localizations.dart';

class DrawerWidget extends StatefulWidget {
  final Function() openDrawer;

  const DrawerWidget({
    super.key,
    required this.openDrawer,
  });

  @override
  DrawerWidgetState createState() => DrawerWidgetState();
}

class DrawerWidgetState extends State<DrawerWidget> {
  final ThemeController _themeController = Get.find<ThemeController>();
  final ColorController _colorController = Get.find<ColorController>();
  bool _isAuthenticated = false;
  String? _username;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadUsername();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
        });
      }
    });
  }

  void _checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        if (user != null) {
          _updateCurrentUser();
        } else {
          setState(() {
            _isAuthenticated = false;
            _currentUser = null;
          });
        }
      }
    });
  }

  void _updateCurrentUser() async {
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    if (account == null && _firebaseAuth.currentUser != null) {
      account = await _googleSignIn.signInSilently();
    }
    if (mounted) {
      setState(() {
        _isAuthenticated = _firebaseAuth.currentUser != null;
        _currentUser = account;
      });
    }
  }

  void _setSystemUiOverlayStyle(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    ));
  }

  Future<void> _signInWithGoogle() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        await _firebaseAuth.signInWithCredential(credential);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'username', googleSignInAccount.displayName ?? '');
        await prefs.setString('email', googleSignInAccount.email);

        _updateCurrentUser();
        Get.snackbar(
          l10n.welcome,
          l10n.signedInSuccessfully,
          backgroundColor: Colors.green.withOpacity(0.2),
          colorText: _colorController.textColor.value,
        );

        Phoenix.rebirth(context);
      }
    } catch (e) {}
  }

  void _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
    });
  }

  void _showAudioCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Audio Cache Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _colorController.textColor.value,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: _colorController.iconColor.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>>(
                future: AudioService.instance.getCacheStats(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final stats = snapshot.data!;
                    return Column(
                      children: [
                        Text(
                          'Total cached hymns: ${stats['totalEntries']}',
                          style: TextStyle(
                            color: _colorController.textColor.value,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'With audio: ${stats['withAudio']}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Without audio: ${stats['withoutAudio']}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        if (stats['lastChecked'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last checked: ${_formatDate(stats['lastChecked'])}',
                            style: TextStyle(
                              color: _colorController.textColor.value.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NeumorphicButton(
                    onPressed: () async {
                      await AudioService.instance.clearExpiredCache();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Expired cache cleared'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: NeumorphicStyle(
                      color: Colors.orange.withOpacity(0.1),
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
                      depth: 2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Clear Expired',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  NeumorphicButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: _colorController.backgroundColor.value,
                          title: Text(
                            'Clear All Cache',
                            style: TextStyle(
                              color: _colorController.textColor.value,
                            ),
                          ),
                          content: Text(
                            'This will remove all cached audio availability data. The app will need to check audio availability again.',
                            style: TextStyle(
                              color: _colorController.textColor.value,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: _colorController.textColor.value,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        await AudioService.instance.clearAllCache();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('All cache cleared'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: NeumorphicStyle(
                      color: Colors.red.withOpacity(0.1),
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
                      depth: 2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: _colorController.drawerColor.value,
      child: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: _colorController.textColor.value,
                  displayColor: _colorController.textColor.value,
                ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (_currentUser == null && _username != null)
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: _colorController.drawerColor.value,
                  ),
                  accountName: Text(
                    _username!,
                    style: TextStyle(
                      color: _colorController.textColor.value,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: null,
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: _colorController.primaryColor.value,
                    child: Icon(
                      Icons.person,
                      color: _colorController.iconColor.value,
                      size: 40,
                    ),
                  ),
                ),
              if (_isAuthenticated && _currentUser != null)
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: _colorController.drawerColor.value,
                  ),
                  accountName: Text(
                    _currentUser?.displayName ?? 'User',
                    style: TextStyle(
                      color: _colorController.textColor.value,
                    ),
                  ),
                  accountEmail: Text(
                    _currentUser?.email ?? '',
                    style: TextStyle(
                      color: _colorController.textColor.value,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: _colorController.primaryColor.value,
                    child: _currentUser?.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _currentUser!.photoUrl!,
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) =>
                                CircularProgressIndicator(
                              color: _colorController.primaryColor.value,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: _colorController.iconColor.value,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: _colorController.iconColor.value,
                          ),
                  ),
                ),
              if (!_isAuthenticated)
                ListTile(
                  leading: Icon(
                    Icons.login,
                    color: _colorController.iconColor.value,
                  ),
                  title: Text(
                    l10n.signIn,
                    style: TextStyle(
                      color: _colorController.textColor.value,
                    ),
                  ),
                  onTap: _signInWithGoogle,
                ),
              ListTile(
                leading: Icon(
                  Icons.music_note,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.hymns,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.back(),
              ),
              if (_isAuthenticated)
                ListTile(
                  leading: Icon(
                    Icons.add,
                    color: _colorController.iconColor.value,
                  ),
                  title: Text(
                    l10n.createHymn,
                    style: TextStyle(
                      color: _colorController.textColor.value,
                    ),
                  ),
                  onTap: () => Get.to(() => const CreateHymnPage()),
                ),
              ListTile(
                leading: Icon(
                  Icons.library_add,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.additionalHymns,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.to(() => const FirebaseHymnsScreen()),
              ),
              if (_currentUser?.email == 'manassehrandriamitsiry@gmail.com')
                ListTile(
                  leading: Icon(
                    Icons.admin_panel_settings,
                    color: _colorController.iconColor.value,
                  ),
                  title: Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: _colorController.textColor.value,
                    ),
                  ),
                  onTap: () => Get.to(() => const AdminPanelScreen()),
                ),
              ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.favoriteHymns,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.to(() => FavoritesPage()),
              ),
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.hymnHistory,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.to(() => HistoryScreen()),
              ),
              ListTile(
                leading: Icon(
                  Icons.color_lens,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.changeColor,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: _colorController.backgroundColor.value,
                    child: ColorPickerWidget(),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.font_download,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.fontStyle,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: _colorController.backgroundColor.value,
                    child: FontPickerWidget(),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.announcements,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.to(() => const AnnouncementScreen()),
              ),
              ListTile(
                leading: Icon(
                  Icons.menu_book,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.bible,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.to(() => const EnhancedBibleReaderScreen()),
              ),
              ListTile(
                leading: Icon(
                  Icons.storage,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  'Audio Cache',
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => _showAudioCacheDialog(),
              ),
              if (_isAuthenticated)
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: _colorController.iconColor.value,
                  ),
                  title: Text(
                    l10n.signOut,
                    style: TextStyle(
                      color: _colorController.textColor.value,
                    ),
                  ),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    setState(() {
                      _isAuthenticated = false;
                      _currentUser = null;
                    });
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: _colorController.iconColor.value,
                ),
                title: Text(
                  l10n.aboutUs,
                  style: TextStyle(
                    color: _colorController.textColor.value,
                  ),
                ),
                onTap: () => Get.to(() => const AboutScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
