import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../controller/theme_controller.dart';
import '../controller/font_controller.dart';
import '../controller/color_controller.dart';
import '../screen/favorite/favorites_screen.dart';
import '../screen/hymn/create_hymn_page.dart';
import '../screen/admin/admin_panel_screen.dart';
import '../screen/about/about_screen.dart';
import '../screen/history/history_screen.dart';
import 'color_picker_widget.dart';
import 'font_picker_widget.dart';

class DrawerWidget extends StatefulWidget {
  final Function() openDrawer;

  const DrawerWidget({
    Key? key,
    required this.openDrawer,
  }) : super(key: key);

  @override
  DrawerWidgetState createState() => DrawerWidgetState();
}

class DrawerWidgetState extends State<DrawerWidget> {
  final ThemeController _themeController = Get.find<ThemeController>();
  final FontController _fontController = Get.find<FontController>();
  final ColorController _colorController = Get.find<ColorController>();
  bool _isAuthenticated = false;
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
    _themeController.isDarkMode.listen((isDarkMode) {
      _setSystemUiOverlayStyle(isDarkMode);
    });
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
  }

  void _checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _updateCurrentUser();
      } else {
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
        });
      }
    });
  }

  void _updateCurrentUser() async {
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    if (account == null && _firebaseAuth.currentUser != null) {
      account = await _googleSignIn.signInSilently();
    }
    setState(() {
      _isAuthenticated = _firebaseAuth.currentUser != null;
      _currentUser = account;
    });
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
      // Clear any existing auth state
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await _firebaseAuth.setPersistence(Persistence.NONE);

      // Start fresh sign in
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
        _updateCurrentUser();
        Get.snackbar(
          'Tongasoa',
          'Tafiditra ianao.',
          backgroundColor: Colors.green.withOpacity(0.2),
          colorText: _colorController.textColor.value,
          icon: Icon(Icons.check, color: _colorController.iconColor.value),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Nisy olana',
        'Avereno atao.',
        backgroundColor: Colors.red.withOpacity(0.2),
        colorText: _colorController.textColor.value,
        icon:
            Icon(Icons.warning_amber, color: _colorController.iconColor.value),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Material(
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
                  if (_currentUser == null) const SizedBox(height: 50),
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
                        'Miditra',
                        style: TextStyle(
                          color: _colorController.textColor.value,
                        ),
                      ),
                      onTap: _signInWithGoogle,
                    ),
                  if (_isAuthenticated) ...[
                    ListTile(
                      leading: Icon(
                        Icons.add,
                        color: _colorController.iconColor.value,
                      ),
                      title: Text(
                        'Hamorona hira',
                        style: TextStyle(
                          color: _colorController.textColor.value,
                        ),
                      ),
                      onTap: () => Get.to(() => const CreateHymnPage()),
                    ),
                    if (_currentUser?.email ==
                        'manassehrandriamitsiry@gmail.com')
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
                  ],
                  ListTile(
                    leading: Icon(
                      Icons.favorite,
                      color: _colorController.iconColor.value,
                    ),
                    title: Text(
                      'Hira tiako',
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
                      'Tantara',
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
                      'Loko',
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
                      'Endrika soratra',
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
                      Icons.info,
                      color: _colorController.iconColor.value,
                    ),
                    title: Text(
                      'Mombamomba',
                      style: TextStyle(
                        color: _colorController.textColor.value,
                      ),
                    ),
                    onTap: () => Get.to(() => const AboutScreen()),
                  ),
                  if (_isAuthenticated)
                    ListTile(
                      leading: Icon(Icons.logout,
                          color: _colorController.iconColor.value),
                      title: Text(
                        'Hivoaka',
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
                ],
              ),
            ),
          ),
        ));
  }
}
