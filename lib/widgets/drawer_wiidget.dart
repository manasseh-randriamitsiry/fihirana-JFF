import 'package:cached_network_image/cached_network_image.dart';
import 'package:fihirana/screen/about/about_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../controller/theme_controller.dart';
import '../controller/font_controller.dart';
import '../screen/favorite/favorites_screen.dart';
import '../screen/hymn/create_hymn_page.dart';
import 'color_picker_widget.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  DrawerScreenState createState() => DrawerScreenState();
}

class DrawerScreenState extends State<DrawerScreen> {
  final ThemeController _themeController = Get.put(ThemeController());
  final FontController _fontController = Get.put(FontController());
  bool _isAuthenticated = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  GoogleSignInAccount? _currentUser;

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
        Get.snackbar('Tongasoa', 'Tafiditra ianao.',
            backgroundColor: Colors.green.withOpacity(0.2),
            colorText: Colors.black,
            icon: const Icon(Icons.check, color: Colors.black));
      }
    } catch (e) {
      Get.snackbar('Nisy olana', 'Avereno atao.',
          backgroundColor: Colors.red.withOpacity(0.2),
          colorText: Colors.black,
          icon: const Icon(Icons.warning_amber, color: Colors.black));
    }
  }

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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = _themeController.isDarkMode.value;
    _setSystemUiOverlayStyle(isDarkMode);
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 1200;
    final theme = Theme.of(context);
    final drawerColor = theme.dividerColor;
    final textColor = theme.hintColor;
    return Drawer(
      backgroundColor: drawerColor,
      width: isDesktop ? 300 : (4 * screenWidth / 5),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_currentUser == null)
            const SizedBox(
              height: 50,
            ),
          if (_currentUser != null)
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUser!.displayName ?? '',
                style: TextStyle(color: textColor),
              ),
              accountEmail: Text(
                _currentUser!.email,
                style: TextStyle(color: textColor),
              ),
              currentAccountPicture: CachedNetworkImage(
                imageUrl: _currentUser!.photoUrl ?? '',
                // Assuming _currentUser has a photoUrl property
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  backgroundImage: imageProvider,
                ),
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(
                  Icons.error,
                  color: textColor,
                ),
              ),
            ),
          ListTile(
            leading: Icon(Icons.brightness_6, color: textColor),
            title: Text(
              'Maizina/Mazava',
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              _themeController.toggleTheme();
            },
          ),
          if (!_isAuthenticated)
            ListTile(
              leading: Icon(Icons.login, color: textColor),
              title: Text(
                'Miditra',
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                _signInWithGoogle();
              },
            ),
          if (_isAuthenticated)
            ListTile(
              leading: Icon(Icons.add, color: textColor),
              title: Text(
                'Hapiditra hira',
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                Get.to(const CreateHymnPage());
              },
            ),
          ListTile(
            leading: Icon(Icons.favorite, color: textColor),
            title: Text(
              'Tiana',
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              Get.to(FavoritesPage());
            },
          ),
          if (_isAuthenticated)
            ListTile(
              leading: Icon(Icons.logout, color: textColor),
              title: Text(
                'Hivoaka',
                style: TextStyle(
                  color: textColor,
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
          ExpansionTile(
            leading: Icon(Icons.font_download, color: textColor),
            title: Text(
              'Endrika soratra',
              style: TextStyle(color: textColor),
            ),
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  itemCount: _fontController.availableFonts.length,
                  itemBuilder: (context, index) {
                    final fontName = _fontController.availableFonts[index];
                    return Obx(() => RadioListTile<String>(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fontName,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Jesosy Famonjena Fahamarinantsika',
                                style: _fontController.getFontStyle(
                                  fontName,
                                  TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          value: fontName,
                          groupValue: _fontController.currentFont.value,
                          onChanged: (value) {
                            if (value != null) {
                              _fontController.changeFont(value);
                            }
                          },
                        ));
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.color_lens, color: textColor),
            title: Text(
              'Loko',
              style: TextStyle(color: textColor),
            ),
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: SingleChildScrollView(
                  child: ColorPickerWidget(),
                ),
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: textColor),
            title: Text(
              '?',
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              Get.to(const AboutScreen());
            },
          ),
        ],
      ),
    );
  }
}

Color getTextTheme(BuildContext context) {
  return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
}
