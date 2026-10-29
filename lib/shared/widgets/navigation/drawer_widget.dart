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
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';

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
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppScale.gutter, AppScale.space24, AppScale.gutter, AppScale.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: type.bodySmall
                  ?.copyWith(color: s.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppScale.space8),
          Container(height: AppScale.ruleBar, color: s.ruleFirm),
        ],
      ),
    );
  }

  /// The drawer's own navigation row: the register row, which is the object the
  /// rest of the app already reads, so a drawer entry and a hymn entry agree.
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final AppSurfaces s = AppSurfaces.of(context);
    final Color ink = isDestructive
        ? Theme.of(context).colorScheme.error
        : isActive
            ? s.accent
            : s.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppScale.gutter, vertical: AppScale.space4),
      child: AppRegisterRow(
        title: title,
        selected: isActive,
        destructive: isDestructive,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        // A navigation entry does not lead somewhere deeper: no chevron.
        trailing: const SizedBox.shrink(),
        leadingWidget: Icon(icon, size: AppScale.iconLg, color: ink),
      ),
    );
  }

  /// The drawer is mounted in MaterialApp's `builder`, which sits outside the
  /// Navigator's Overlay, so an IconButton here must not carry a tooltip: a
  /// RawTooltip without an Overlay ancestor throws the moment it is shown.
  Widget _buildCloseButton(BuildContext context, Color onBand) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).closeButtonTooltip,
      child: Ink(
        width: AppScale.hitTarget,
        height: AppScale.hitTarget,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppScale.radiusControl),
        ),
        child: InkWell(
          onTap: widget.openDrawer,
          customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppScale.radiusControl)),
          child:
              Icon(Icons.close_rounded, color: onBand, size: AppScale.iconLg),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final Color onBand = s.ink;
    final Color onBandQuiet = s.muted;
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
      padding: const EdgeInsets.fromLTRB(
          AppScale.gutter, AppScale.space16, AppScale.gutter, AppScale.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppScale.hitTarget,
                height: AppScale.hitTarget,
                decoration: BoxDecoration(
                  color: s.paper3,
                  border: Border.all(color: s.rule, width: AppScale.ruleHair),
                  borderRadius: BorderRadius.circular(AppScale.radiusControl),
                ),
                clipBehavior: Clip.hardEdge,
                child: _isAuthenticated && photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: SizedBox(
                            width: AppScale.iconLg,
                            height: AppScale.iconLg,
                            child: CircularProgressIndicator(
                              color: onBand,
                              strokeWidth: AppScale.ruleBar,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          color: onBand,
                          size: AppScale.iconLg,
                        ),
                      )
                    : Icon(Icons.person_rounded,
                        color: onBand, size: AppScale.iconLg),
              ),
              const SizedBox(width: AppScale.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.titleMedium?.copyWith(color: onBand),
                    ),
                    const SizedBox(height: AppScale.space2),
                    Text(
                      _isAuthenticated && (email?.isNotEmpty ?? false)
                          ? email!
                          : l10n.guest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.bodySmall?.copyWith(color: onBandQuiet),
                    ),
                  ],
                ),
              ),
              if (isMobile) _buildCloseButton(context, onBand),
            ],
          ),
          if (!_isAuthenticated) ...[
            const SizedBox(height: AppScale.space16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login_rounded, size: AppScale.iconMd),
                label: Text(l10n.signIn),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // The drawer has no stock of its own: it is the page it opens on,
            // and only the things inside it are drawn.
            type: MaterialType.transparency,
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
                  padding: const EdgeInsets.only(bottom: AppScale.space16),
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
                        icon: Icons.add_circle_rounded,
                        title: l10n.createHymn,
                        isActive: currentRoute == '/create_hymn',
                        onTap: () => Get.toNamed('/create_hymn'),
                      ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.library_music_rounded,
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
                        icon: Icons.admin_panel_settings_rounded,
                        title: l10n.adminPanel,
                        isActive: currentRoute == '/admin',
                        onTap: () => Get.toNamed('/admin'),
                      ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.settings_rounded,
                      title: l10n.settings,
                      isActive: currentRoute == '/settings',
                      onTap: () => Get.toNamed('/settings'),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.info_rounded,
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
