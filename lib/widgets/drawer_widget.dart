import 'dart:async';
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
import 'color_picker_widget.dart';
import 'font_picker_widget.dart';

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
  StreamSubscription<User?>? _authSubscription;

  late final Color _drawerColor;
  late final Color _textColor;
  late final Color _primaryColor;
  late final Color _iconColor;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _initializeAuth();
    _initializeColors();
  }

  void _initializeColors() {
    _drawerColor = _colorController.drawerColor.value;
    _textColor = _colorController.textColor.value;
    _primaryColor = _colorController.primaryColor.value;
    _iconColor = _colorController.iconColor.value;
  }

  void _initializeAuth() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
        });
        if (user != null) {
          _updateCurrentUser();
        } else {
          setState(() {
            _currentUser = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
          'Tongasoa',
          'Tafiditra ianao.',
          backgroundColor: Colors.green.withOpacity(0.2),
          colorText: _colorController.textColor.value,
        );

        Phoenix.rebirth(context);
      }
    } catch (e) {}
  }

  void _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
          color: _drawerColor,
          child: SafeArea(
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: _textColor,
                      displayColor: _textColor,
                    ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_currentUser == null && _username != null)
                    UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: _drawerColor,
                      ),
                      accountName: Text(
                        _username!,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      accountEmail: null,
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: _primaryColor,
                        child: Icon(
                          Icons.person,
                          color: _iconColor,
                          size: 40,
                        ),
                      ),
                    ),
                  if (_isAuthenticated && _currentUser != null)
                    UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: _drawerColor,
                      ),
                      accountName: Text(
                        _currentUser?.displayName ?? 'User',
                        style: TextStyle(
                          color: _textColor,
                        ),
                      ),
                      accountEmail: Text(
                        _currentUser?.email ?? '',
                        style: TextStyle(
                          color: _textColor,
                        ),
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: _primaryColor,
                        child: _currentUser?.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _currentUser!.photoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    color: _iconColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: _iconColor,
                              ),
                      ),
                    ),
                  if (!_isAuthenticated)
                    ListTile(
                      leading: Icon(
                        Icons.login,
                        color: _iconColor,
                      ),
                      title: Text(
                        'Miditra',
                        style: TextStyle(
                          color: _textColor,
                        ),
                      ),
                      onTap: _signInWithGoogle,
                    ),
                  ListTile(
                    leading: Icon(
                      Icons.music_note,
                      color: _iconColor,
                    ),
                    title: Text(
                      'Fihirana',
                      style: TextStyle(
                        color: _textColor,
                      ),
                    ),
                    onTap: () => Get.back(),
                  ),
                  if (_isAuthenticated)
                    ListTile(
                      leading: Icon(
                        Icons.add,
                        color: _iconColor,
                      ),
                      title: Text(
                        'Hamorona hira',
                        style: TextStyle(
                          color: _textColor,
                        ),
                      ),
                      onTap: () => Get.to(() => const CreateHymnPage()),
                    ),
                  ListTile(
                    leading: Icon(
                      Icons.library_add,
                      color: _iconColor,
                    ),
                    title: Text(
                      'Fihirana Fanampiny',
                      style: TextStyle(
                        color: _textColor,
                      ),
                    ),
                    onTap: () => Get.to(() => const FirebaseHymnsScreen()),
                  ),
                  if (_currentUser?.email == 'manassehrandriamitsiry@gmail.com')
                    ListTile(
                      leading: Icon(
                        Icons.admin_panel_settings,
                        color: _iconColor,
                      ),
                      title: Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: _textColor,
                        ),
                      ),
                      onTap: () => Get.to(() => const AdminPanelScreen()),
                    ),
                  ListTile(
                    leading: Icon(
                      Icons.favorite,
                      color: _iconColor,
                    ),
                    title: Text(
                      'Hira tiana',
                      style: TextStyle(
                        color: _textColor,
                      ),
                    ),
                    onTap: () => Get.to(() => FavoritesPage()),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.history,
                      color: _iconColor,
                    ),
                    title: Text(
                      'Tantaran-kira',
                      style: TextStyle(
                        color: _textColor,
                      ),
                    ),
                    onTap: () => Get.to(() => HistoryScreen()),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.color_lens,
                      color: _iconColor,
                    ),
                    title: Text(
                      'Hanova loko',
                      style: TextStyle(
                        color: _textColor,
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
                      color: _iconColor,
                    ),
                    title: Text(
                      "Endrikin'ny soratra",
                      style: TextStyle(
                        color: _textColor,
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
                      color: _iconColor,
                    ),
                    title: Text(
                      'Filazana',
                      style: TextStyle(
                        color: _textColor,
                      ),
                    ),
                    onTap: () => Get.to(() => const AnnouncementScreen()),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.menu_book,
                      color: _iconColor,
                    ),
                    title: Text(
                      'Baiboly',
                      style: TextStyle(
                        color: _textColor,
                      ),
                    ),
                    onTap: () => Get.to(() => const EnhancedBibleReaderScreen()),
                  ),
                  if (_isAuthenticated)
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: _iconColor,
                      ),
                      title: Text(
                        'Hivoaka',
                        style: TextStyle(
                          color: _textColor,
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
                      color: _iconColor,
                    ),
                    title: Text(
                      'Mombamomba',
                      style: TextStyle(
                        color: _textColor,
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
