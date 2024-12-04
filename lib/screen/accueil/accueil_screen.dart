import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/theme_controller.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../utility/screen_util.dart';
import '../favorite/favorites_screen.dart';
import '../hymn/edit_hymn_screen.dart';
import '../hymn/hymn_detail_screen.dart';

class AccueilScreen extends StatefulWidget {
  final Function() openDrawer;

  const AccueilScreen({
    Key? key,
    required this.openDrawer,
  }) : super(key: key);

  @override
  AccueilScreenState createState() => AccueilScreenState();
}

class AccueilScreenState extends State<AccueilScreen> {
  final HymnService _hymnService = HymnService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ThemeController _themeController = Get.find<ThemeController>();
  final ColorController _colorController = Get.find<ColorController>();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = true;
  String _username = '';
  List<Hymn> _hymns = [];
  List<Hymn> _filteredHymns = [];
  Map<String, String> _favoriteStatuses = {};
  int _profileTapCount = 0;
  DateTime? _lastTapTime;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehrandriamitsir@gmail.com';
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // First check SharedPreferences for manually entered username
    String? username = prefs.getString('username');
    if (username != null && username.isNotEmpty) {
      return username;
    }

    // If no username in SharedPreferences, check Firebase
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser?.displayName != null &&
        firebaseUser!.displayName!.isNotEmpty) {
      return firebaseUser.displayName!;
    }

    // Default fallback
    return 'Jesosy Famonjena Fahamarinantsika';
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatuses();
    _hymnService.checkPendingSyncs();
    _loadUsername();
    _fetchHymns();
    // Initialize controllers
    Get.put(ThemeController());
    Get.put(ColorController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getHymnNumberValue(String hymnNumber) {
    // Extract only numbers from the hymn number
    String numStr = hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
    // Pad with leading zeros to ensure proper string comparison
    // This will handle up to 999 hymns (adjust width if needed)
    return int.tryParse(numStr) ?? 0;
  }

  void _fetchHymns() {
    _hymnService.getHymnsStream().listen((QuerySnapshot snapshot) {
      setState(() {
        _hymns = snapshot.docs
            .map((doc) => Hymn.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        // Sort hymns by number
        _hymns.sort((a, b) {
          int numA = _getHymnNumberValue(a.hymnNumber);
          int numB = _getHymnNumberValue(b.hymnNumber);

          // If numbers are equal, compare the original strings
          if (numA == numB) {
            return a.hymnNumber.compareTo(b.hymnNumber);
          }

          return numA.compareTo(numB);
        });

        _filteredHymns = List.from(_hymns);
        _isLoading = false;
      });
    });
  }

  void _filterHymns() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHymns = _hymns
          .where((hymn) =>
              hymn.hymnNumber.toLowerCase().contains(query) ||
              hymn.title.toLowerCase().contains(query) ||
              hymn.verses.any((verse) => verse.toLowerCase().contains(query)))
          .toList();

      // Use the same sorting for filtered results
      _filteredHymns.sort((a, b) {
        int numA = _getHymnNumberValue(a.hymnNumber);
        int numB = _getHymnNumberValue(b.hymnNumber);

        if (numA == numB) {
          return a.hymnNumber.compareTo(b.hymnNumber);
        }

        return numA.compareTo(numB);
      });
    });
  }

  Future<void> _deleteHymn(Hymn hymn) async {
    bool authenticated = false;
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isBiometricSupported = await _auth.isDeviceSupported();

      if (canCheckBiometrics && isBiometricSupported) {
        authenticated = await _auth.authenticate(
          localizedReason:
              'Ampidiro ny rantsan-tànanao hanamafisana ny famafana.',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } else {
        authenticated = await _auth.authenticate(
          localizedReason:
              'Ilaina ny rantsan-tànanao, endrikao, na tenimiafinao hanamafisana ny famafana.',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Authentication error: $e');
      }
    }

    if (authenticated) {
      await _hymnService.deleteHymn(hymn.id);
      showSnackbarSuccessMessage(title: "Voafafa", message: "soamantsara");
    } else {
      showSnackbarErrorMessage(
          title: 'Filazana', message: 'Tsy manana fahefana ianao.');
    }
  }

  Future<void> _toggleFavorite(Hymn hymn) async {
    try {
      // Update local state immediately
      final oldStatus = Map<String, String>.from(_favoriteStatuses);

      setState(() {
        if (_favoriteStatuses.containsKey(hymn.id)) {
          _favoriteStatuses.remove(hymn.id);
        } else {
          _favoriteStatuses[hymn.id] =
              FirebaseAuth.instance.currentUser != null ? 'cloud' : 'local';
        }
      });

      // Schedule the actual toggle
      final completer = Completer<void>();

      SchedulerBinding.instance.scheduleTask(() async {
        try {
          await _hymnService.toggleFavorite(hymn);

          // If user is not logged in, show login suggestion
          if (FirebaseAuth.instance.currentUser == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Voatahiry eto amin\'ny finday. Raha te-hitahiry any @ kaonty, dia midira'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.blue,
              ),
            );
          }

          // Refresh actual status
          await _loadFavoriteStatuses();
          completer.complete();
        } catch (e) {
          // Revert state on error
          if (mounted) {
            setState(() {
              _favoriteStatuses = oldStatus;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tsy nahomby ny fitahirizana'),
                backgroundColor: Colors.red,
              ),
            );
          }
          completer.completeError(e);
        }
      }, Priority.animation);

      return completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('Error in toggle favorite: $e');
      }
      rethrow;
    }
  }

  String _getPreviewText(Hymn hymn) {
    if (hymn.verses.isEmpty) return '';
    final firstVerse = hymn.verses[0];
    if (firstVerse.length > 50) {
      return '${firstVerse.substring(0, 50)}...';
    }
    return firstVerse;
  }

  List<Hymn> _sortHymns(List<Hymn> hymns) {
    hymns.sort((a, b) {
      // Extract numbers from hymn numbers
      int numA =
          int.tryParse(a.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numB =
          int.tryParse(b.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });
    return hymns;
  }

  Future<void> _loadFavoriteStatuses() async {
    try {
      final completer = Completer<void>();

      SchedulerBinding.instance.scheduleTask(() async {
        final statuses = await _hymnService.getFavoriteStatusStream().first;
        if (mounted) {
          setState(() {
            _favoriteStatuses = statuses;
          });
        }
        completer.complete();
      }, Priority.animation);

      return completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorite statuses: $e');
      }
    }
  }

  List<Hymn> _filterHymnList(List<DocumentSnapshot> docs) {
    List<Hymn> hymns = docs
        .map((doc) =>
            Hymn.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    hymns = _sortHymns(hymns);

    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isEmpty) {
      return hymns;
    }

    return hymns
        .where((hymn) =>
            hymn.hymnNumber.toLowerCase().contains(searchQuery) ||
            hymn.title.toLowerCase().contains(searchQuery) ||
            hymn.verses
                .any((verse) => verse.toLowerCase().contains(searchQuery)))
        .toList();
  }

  Widget _buildHymnListItem(
      Hymn hymn, BuildContext context, TextStyle defaultTextStyle, Color iconColor) {
    final theme = Theme.of(context);
    final textColor = _colorController.textColor.value;
    final accentColor = _colorController.accentColor.value;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: theme.primaryColor,
      child: ListTile(
        title: Text(
          hymn.title,
          style: defaultTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: _isAdmin
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nampiditra: ${hymn.createdBy}',
                    style: defaultTextStyle.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  if (hymn.createdAt != null)
                    Text(
                      'Daty: ${DateFormat('dd/MM/yyyy').format(hymn.createdAt)}',
                      style: defaultTextStyle.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hymn.hymnHint != null && hymn.hymnHint!.isNotEmpty)
                    Text(
                      hymn.hymnHint!,
                      style: defaultTextStyle.copyWith(
                        color: textColor.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    _getPreviewText(hymn),
                    style: defaultTextStyle.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
        leading: CircleAvatar(
          backgroundColor: accentColor,
          child: Text(
            hymn.hymnNumber,
            style: defaultTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _favoriteStatuses.containsKey(hymn.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _favoriteStatuses.containsKey(hymn.id)
                    ? (_favoriteStatuses[hymn.id] == 'cloud'
                        ? Colors.red
                        : iconColor)
                    : iconColor,
              ),
              onPressed: () => _toggleFavorite(hymn),
            ),
            if (_isAdmin)
              IconButton(
                icon: Icon(Icons.edit, color: iconColor),
                onPressed: () => _showEditDialog(context),
              ),
            if (_isAdmin)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteHymn(hymn),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HymnDetailScreen(hymn: hymn),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final textColor = _colorController.textColor.value;
      final accentColor = _colorController.accentColor.value;

      return DrawerHeader(
        decoration: BoxDecoration(
          color: theme.primaryColor,
        ),
        child: GestureDetector(
          onTap: () {
            final now = DateTime.now();
            if (_lastTapTime != null &&
                now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
              _profileTapCount = 0;
            }
            _lastTapTime = now;

            setState(() {
              _profileTapCount++;
              if (_profileTapCount == 5) {
                _profileTapCount = 0;
                _showAdminPanel();
              }
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: accentColor,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _username.isEmpty ? 'Tsy mbola tafiditra' : _username,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    // TODO: Implement upload functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hampiditra hira vaovao...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hanova hira...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAdminPanel() {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tsy manana alalana ianao'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Admin Panel',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(
                'Hampiditra hira',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showUploadDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(
                'Hanova hira',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Obx(() {
        final theme = Theme.of(context);
        final textColor = colorController.textColor.value;
        final accentColor = colorController.accentColor.value;
        final backgroundColor = colorController.backgroundColor.value;
        final iconColor = colorController.iconColor.value;
        final defaultTextStyle = TextStyle(
          color: textColor,
          inherit: true,
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.menu,
                color: iconColor,
              ),
              onPressed: widget.openDrawer,
            ),
            title: Text(
              'JFF',
              style: defaultTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: iconColor,
                ),
                onPressed: () => Get.to(() => FavoritesPage()),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  style: defaultTextStyle,
                  decoration: InputDecoration(
                    labelText: 'Hitady hira',
                    labelStyle: defaultTextStyle.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: iconColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: textColor,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    _filterHymns();
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _hymnService.getHymnsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Nisy olana: ${snapshot.error}',
                          style: defaultTextStyle,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final hymns = _filterHymnList(snapshot.data?.docs ?? []);

                    if (hymns.isEmpty) {
                      return Center(
                        child: Text(
                          'Tsy misy hira',
                          style: defaultTextStyle,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: hymns.length,
                      itemBuilder: (context, index) {
                        final hymn = hymns[index];
                        return _buildHymnListItem(
                          hymn,
                          context,
                          defaultTextStyle,
                          iconColor,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: _isAdmin
              ? FloatingActionButton(
                  backgroundColor: accentColor,
                  child: Icon(Icons.add, color: textColor),
                  onPressed: () => _showUploadDialog(context),
                )
              : null,
        );
      }),
    );
  }

  void _navigateToEditScreen(BuildContext context, Hymn hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHymnScreen(hymn: hymn),
      ),
    );
  }

  Future<void> _loadUsername() async {
    final username = await getUsername();
    setState(() {
      _username = username;
    });
  }
}
