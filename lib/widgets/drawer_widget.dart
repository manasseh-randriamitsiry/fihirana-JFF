import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/color_controller.dart';
import '../controller/shell_controller.dart';
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
          backgroundColor: Colors.green.withValues(alpha: 0.2),
          colorText: _colorController.textColor.value,
        );

        if (mounted) {
          Phoenix.rebirth(context);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
    });
  }

  void _showAudioCacheDialog(AppLocalizations l10n) {
    Get.dialog(
      Dialog(
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
                    l10n.audioCacheManagement,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _colorController.textColor.value,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: _colorController.iconColor.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: _colorController.textColor.value.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: isActive
          ? BoxDecoration(
              color:
                  _colorController.primaryColor.value.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _colorController.primaryColor.value.withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? _colorController.primaryColor.value
              : (color ?? _colorController.iconColor.value),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive
                ? _colorController.primaryColor.value
                : (color ?? _colorController.textColor.value),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _colorController.primaryColor.value,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: _colorController.drawerColor.value,
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isAuthenticated ? null : _signInWithGoogle,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isAuthenticated &&
                              (_currentUser?.photoUrl != null ||
                                  _firebaseAuth.currentUser?.photoURL != null)
                          ? CachedNetworkImage(
                              imageUrl: _currentUser?.photoUrl ??
                                  _firebaseAuth.currentUser!.photoURL!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(
                                color: _colorController.accentColor.value,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 40,
                                color: _colorController.backgroundColor.value,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 40,
                              color: _colorController.backgroundColor.value,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAuthenticated
                            ? (_currentUser?.displayName ??
                                _firebaseAuth.currentUser?.displayName ??
                                _username ??
                                'User')
                            : (_username ?? l10n.guest),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isAuthenticated) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.email ??
                              _firebaseAuth.currentUser?.email ??
                              '',
                          style: TextStyle(
                            color: _colorController.backgroundColor.value
                                .withValues(alpha: .95),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _signInWithGoogle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _colorController.primaryColor.value,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.signIn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: Obx(() {
              final currentRoute =
                  Get.find<ShellController>().currentRoute.value;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionHeader(l10n.library),
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: l10n.home,
                    isActive: currentRoute == '/home',
                    onTap: () => Get.offAllNamed('/home'),
                  ),
                  if (_isAuthenticated)
                    _buildDrawerItem(
                      icon: Icons.add_circle_outline,
                      title: l10n.createHymn,
                      isActive: currentRoute == '/create_hymn',
                      onTap: () => Get.toNamed('/create_hymn'),
                    ),
                  _buildDrawerItem(
                    icon: Icons.library_music_outlined,
                    title: l10n.additionalHymns,
                    isActive: currentRoute == '/firebase_hymns',
                    onTap: () => Get.toNamed('/firebase_hymns'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: l10n.bible,
                    isActive: currentRoute == '/bible',
                    onTap: () => Get.toNamed('/bible'),
                  ),
                  _buildSectionHeader(l10n.personal),
                  _buildDrawerItem(
                    icon: Icons.favorite_border_rounded,
                    title: l10n.favoriteHymns,
                    isActive: currentRoute == '/favorites',
                    onTap: () => Get.toNamed('/favorites'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: l10n.hymnHistory,
                    isActive: currentRoute == '/history',
                    onTap: () => Get.toNamed('/history'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.playlist_play_rounded,
                    title: l10n.playlists,
                    isActive: currentRoute == '/playlists',
                    onTap: () => Get.toNamed('/playlists'),
                  ),
                  _buildSectionHeader(l10n.appSection),
                  _buildDrawerItem(
                    icon: Icons.notifications_none_rounded,
                    title: l10n.announcements,
                    isActive: currentRoute == '/announcements',
                    onTap: () => Get.toNamed('/announcements'),
                  ),
                  if (_currentUser?.email == 'manassehrandriamitsiry@gmail.com')
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: l10n.adminPanel,
                      isActive: currentRoute == '/admin',
                      onTap: () => Get.toNamed('/admin'),
                    ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: l10n.settings,
                    isActive: currentRoute == '/settings',
                    onTap: () => Get.toNamed('/settings'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: l10n.aboutUs,
                    isActive: currentRoute == '/about',
                    onTap: () => Get.toNamed('/about'),
                  ),
                  if (_isAuthenticated)
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: l10n.signOut,
                      color: _colorController.iconColor.value,
                      onTap: () {
                        FirebaseAuth.instance.signOut();
                        setState(() {
                          _isAuthenticated = false;
                          _currentUser = null;
                        });
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
