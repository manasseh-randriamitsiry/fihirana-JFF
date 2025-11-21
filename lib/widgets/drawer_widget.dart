import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/color_controller.dart';
import '../screen/bible/bible_reader_screen.dart';
import '../screen/favorite/favorites_screen.dart';
import '../screen/admin/admin_panel_screen.dart';
import '../screen/about/about_screen.dart';
import '../screen/history/history_screen.dart';
import '../screen/announcement/announcement_screen.dart';
import '../screen/hymn/create_hymn_page.dart';
import '../screen/hymn/firebase_hymns_screen.dart';
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
                          'Total cached hymns: ${stats['total_checked']}',
                          style: TextStyle(
                            color: _colorController.textColor.value,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'With audio: ${stats['with_audio']}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Without audio: ${stats['without_audio']}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
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
                        const SnackBar(
                          content: Text('Expired cache cleared'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: NeumorphicStyle(
                      color: Colors.orange.withOpacity(0.1),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(10)),
                      depth: 2,
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          backgroundColor:
                              _colorController.backgroundColor.value,
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
                          const SnackBar(
                            content: Text('All cache cleared'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: NeumorphicStyle(
                      color: Colors.red.withOpacity(0.1),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(10)),
                      depth: 2,
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: _colorController.textColor.value.withOpacity(0.5),
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
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? _colorController.iconColor.value),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? _colorController.textColor.value,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
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
                        color: Colors.white.withOpacity(0.9),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isAuthenticated && _currentUser?.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _currentUser!.photoUrl!,
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
                            ? (_currentUser?.displayName ?? _username ?? 'User')
                            : (_username ?? 'Guest'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
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
                          _currentUser?.email ?? '',
                          style: TextStyle(
                            color: _colorController.backgroundColor.value
                                .withOpacity(0.95),
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
                              'Sign In',
                              style: TextStyle(
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader('Library'),
                if (_isAuthenticated)
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    title: l10n.createHymn,
                    onTap: () => Get.to(() => const CreateHymnPage()),
                  ),
                _buildDrawerItem(
                  icon: Icons.library_music_outlined,
                  title: l10n.additionalHymns,
                  onTap: () => Get.to(() => const FirebaseHymnsScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.menu_book_rounded,
                  title: l10n.bible,
                  onTap: () => Get.to(() => const BibleReaderScreen()),
                ),
                _buildSectionHeader('Personal'),
                _buildDrawerItem(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.favoriteHymns,
                  onTap: () => Get.to(() => FavoritesPage()),
                ),
                _buildDrawerItem(
                  icon: Icons.history_rounded,
                  title: l10n.hymnHistory,
                  onTap: () => Get.to(() => HistoryScreen()),
                ),
                _buildSectionHeader('Settings'),
                _buildDrawerItem(
                  icon: Icons.color_lens_outlined,
                  title: l10n.changeColor,
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: _colorController.backgroundColor.value,
                      child: ColorPickerWidget(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.font_download_outlined,
                  title: l10n.fontStyle,
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: _colorController.backgroundColor.value,
                      child: FontPickerWidget(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.storage_rounded,
                  title: 'Audio Cache',
                  onTap: _showAudioCacheDialog,
                ),
                _buildSectionHeader('App'),
                _buildDrawerItem(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.announcements,
                  onTap: () => Get.to(() => const AnnouncementScreen()),
                ),
                if (_currentUser?.email == 'manassehrandriamitsiry@gmail.com')
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Panel',
                    onTap: () => Get.to(() => const AdminPanelScreen()),
                  ),
                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: l10n.aboutUs,
                  onTap: () => Get.to(() => const AboutScreen()),
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
            ),
          ),
        ],
      ),
    );
  }
}
