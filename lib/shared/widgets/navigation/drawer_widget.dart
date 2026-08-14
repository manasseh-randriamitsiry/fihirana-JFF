import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/core/controllers/user_controller.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';

import 'package:fihirana/l10n/app_localizations.dart';

class DrawerWidget extends StatefulWidget {
  final Function() openDrawer;

  const DrawerWidget({
    super.key,
    required this.openDrawer,
  });

  @override
  DrawerWidgetState createState() => DrawerWidgetState();
}

class DrawerWidgetState extends State<DrawerWidget>
    with WidgetsBindingObserver {
  late final UserController _userController;
  bool _isAuthenticated = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  StreamSubscription? _googleSignInSubscription;
  StreamSubscription? _authStateSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize UserController with fallback
    try {
      _userController = Get.find<UserController>();
    } catch (e) {
      // UserController not initialized yet, initialize it
      _userController = Get.put(UserController());
    }

    WidgetsBinding.instance.addObserver(this);
    try {
      _googleSignIn = Get.find<GoogleSignIn>();
    } catch (e) {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/contacts.readonly',
        ],
      );
      Get.put(_googleSignIn!);
    }
    _checkAuthStatus();
    _googleSignInSubscription = _googleSignIn?.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
        });
      }
    });
  }

  @override
  void dispose() {
    _googleSignInSubscription?.cancel();
    _authStateSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkAuthStatus() {
    _authStateSubscription =
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
    GoogleSignInAccount? account = _googleSignIn?.currentUser;
    if (account == null && _firebaseAuth.currentUser != null) {
      account = await _googleSignIn?.signInSilently();
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
      await _googleSignIn?.signOut();
      await _firebaseAuth.signOut();

      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn?.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        await _firebaseAuth.signInWithCredential(credential);

        final prefs = await SharedPreferences.getInstance();
        final username = googleSignInAccount.displayName ?? '';
        await prefs.setString('username', username);
        await prefs.setString('email', googleSignInAccount.email);

        // Update the reactive user controller
        await _userController.setUsername(username);
        _userController.setAuthenticated(true);

        _updateCurrentUser();

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          Get.snackbar(
            l10n.welcome,
            l10n.signedInSuccessfully,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            colorText: Theme.of(context).colorScheme.onPrimaryContainer,
          );

          Phoenix.rebirth(context);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isDestructive
        ? colorScheme.errorContainer
        : isActive
            ? colorScheme.secondaryContainer
            : colorScheme.surface;
    final foreground = isDestructive
        ? colorScheme.onErrorContainer
        : isActive
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurface;
    final iconBackground = isDestructive
        ? colorScheme.error.withValues(alpha: .12)
        : isActive
            ? colorScheme.primary.withValues(alpha: .14)
            : colorScheme.surfaceContainerHighest;
    final iconColor = isDestructive
        ? colorScheme.error
        : isActive
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isActive || isDestructive
                  ? foreground.withValues(alpha: .12)
                  : colorScheme.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: foreground,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ),
                  if (isActive)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = _isAuthenticated
        ? (_currentUser?.displayName ??
            _firebaseAuth.currentUser?.displayName ??
            (_userController.username.value.isNotEmpty
                ? _userController.username.value
                : null) ??
            l10n.guest)
        : (_userController.username.value.isNotEmpty
            ? _userController.username.value
            : l10n.guest);
    final email = _currentUser?.email ?? _firebaseAuth.currentUser?.email;
    final photoUrl =
        _currentUser?.photoUrl ?? _firebaseAuth.currentUser?.photoURL;
    final isMobile = MediaQuery.sizeOf(context).width < 800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: .32),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _isAuthenticated && photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person_rounded,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isAuthenticated && (email?.isNotEmpty ?? false)
                              ? email!
                              : l10n.guest,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: .72),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (isMobile)
                    IconButton(
                      onPressed: widget.openDrawer,
                      icon: Icon(
                        Icons.menu_open_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
              if (!_isAuthenticated) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(l10n.signIn),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = math.min(viewportWidth * .85, 420.0);

    // ZoomDrawer can briefly pass a very large horizontal constraint while it
    // opens. Keep this menu at a real drawer width so neither the profile row
    // nor its text can lay out to that transient size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final constrainedWidth = constraints.maxWidth.isFinite
            ? math.min(drawerWidth, constraints.maxWidth)
            : drawerWidth;

        return SizedBox(
          width: constrainedWidth,
          child: Material(
            color: colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: Obx(() {
                final currentRoute =
                    Get.find<ShellController>().currentRoute.value;
                final l10n = AppLocalizations.of(context);
                return ListView(
                  // A single scrollable owns the vertical layout. ZoomDrawer can
                  // briefly provide loose height constraints while animating; an
                  // Expanded inside a Column then overflows on some devices.
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildProfileHeader(context, l10n),
                    _buildSectionHeader(context, l10n.library),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.home_rounded,
                      title: l10n.home,
                      isActive: currentRoute == '/home',
                      onTap: () => Get.offAllNamed('/home'),
                    ),
                    if (_isAuthenticated)
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.add_circle_outline,
                        title: l10n.createHymn,
                        isActive: currentRoute == '/create_hymn',
                        onTap: () => Get.toNamed('/create_hymn'),
                      ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.library_music_outlined,
                      title: l10n.additionalHymns,
                      isActive: currentRoute == '/firebase_hymns',
                      onTap: () => Get.toNamed('/firebase_hymns'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.menu_book_rounded,
                      title: l10n.bible,
                      isActive: currentRoute == '/bible',
                      onTap: () => Get.toNamed('/bible'),
                    ),
                    _buildSectionHeader(context, l10n.personal),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.favorite_border_rounded,
                      title: l10n.favoriteHymns,
                      isActive: currentRoute == '/favorites',
                      onTap: () => Get.toNamed('/favorites'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.history_rounded,
                      title: l10n.hymnHistory,
                      isActive: currentRoute == '/history',
                      onTap: () => Get.toNamed('/history'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.mic_rounded,
                      title: l10n.recordings,
                      isActive: currentRoute == '/recordings',
                      onTap: () => Get.toNamed('/recordings'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.contacts_rounded,
                      title: l10n.contacts,
                      isActive: currentRoute == '/contacts',
                      onTap: () => Get.toNamed('/contacts'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.playlist_play_rounded,
                      title: l10n.playlists,
                      isActive: currentRoute == '/playlists',
                      onTap: () => Get.toNamed('/playlists'),
                    ),
                    _buildSectionHeader(context, l10n.appSection),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.notifications_none_rounded,
                      title: l10n.announcements,
                      isActive: currentRoute == '/announcements',
                      onTap: () => Get.toNamed('/announcements'),
                    ),
                    if (Get.find<AuthController>().isAdmin)
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: l10n.adminPanel,
                        isActive: currentRoute == '/admin',
                        onTap: () => Get.toNamed('/admin'),
                      ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: l10n.settings,
                      isActive: currentRoute == '/settings',
                      onTap: () => Get.toNamed('/settings'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      title: l10n.aboutUs,
                      isActive: currentRoute == '/about',
                      onTap: () => Get.toNamed('/about'),
                    ),
                    if (_isAuthenticated)
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.logout_rounded,
                        title: l10n.signOut,
                        isDestructive: true,
                        onTap: () {
                          FirebaseAuth.instance.signOut();
                          _userController.setAuthenticated(false);
                          setState(() {
                            _isAuthenticated = false;
                            _currentUser = null;
                          });
                        },
                      ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
