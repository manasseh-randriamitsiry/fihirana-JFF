import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../../widgets/drawer_widget.dart';
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
  final ThemeController _themeController = Get.find<ThemeController>();
  final ColorController _colorController = Get.find<ColorController>();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = true;
  String _username = '';
  List<Hymn> _hymns = [];
  List<Hymn> _filteredHymns = [];

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  bool isAdminUser() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehwork@gmail.com';
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
    _fetchHymns();
    _loadUsername();
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
      await _hymnService.toggleFavorite(hymn);
      setState(() {
        _filteredHymns = List.from(_filteredHymns);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tsy afaka novaina ny fanirian\'ny hira'),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildHymnListItem(Hymn hymn, BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    final isAdmin = isAdminUser();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _themeController.isDarkMode.value
              ? _colorController.drawerColor.value
              : _colorController.backgroundColor.value,
          child: Text(
            hymn.hymnNumber,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          hymn.title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: isAdmin
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nampiditra: ${hymn.createdBy}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  if (hymn.createdAt != null)
                    Text(
                      'Daty: ${DateFormat('dd/MM/yyyy').format(hymn.createdAt)}',
                      style: TextStyle(
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
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    _getPreviewText(hymn),
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<List<String>>(
              stream: _hymnService.getFavoriteHymnIdsStream(),
              builder: (context, snapshot) {
                final isFavorite = snapshot.data?.contains(hymn.id) ?? false;
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : textColor,
                  ),
                  onPressed: () => _toggleFavorite(hymn),
                );
              },
            ),
            if (isAdmin)
              IconButton(
                icon: Icon(Icons.edit, color: textColor),
                onPressed: () => _navigateToEditScreen(context, hymn),
              ),
            if (isAdmin)
              IconButton(
                icon: Icon(Icons.delete, color: textColor),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _themeController.isDarkMode.value
            ? _colorController.drawerColor.value
            : _colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: _colorController.iconColor.value,
          ),
          onPressed: widget.openDrawer,
        ),
        title: Text(
          'JFF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: _colorController.textColor.value,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: _colorController.iconColor.value,
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
              style: TextStyle(
                color: _colorController.textColor.value,
              ),
              decoration: InputDecoration(
                labelText: 'Hitady hira',
                labelStyle: TextStyle(
                  color: _colorController.textColor.value.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _colorController.iconColor.value,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: _colorController.textColor.value.withOpacity(0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: _colorController.textColor.value.withOpacity(0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: _colorController.textColor.value,
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
                      style: TextStyle(
                        color: _colorController.textColor.value,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Hymn> hymns = snapshot.data?.docs
                        .map((doc) => Hymn.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList() ??
                    [];

                hymns = _sortHymns(hymns);

                if (hymns.isEmpty) {
                  return Center(
                    child: Text(
                      'Tsy misy hira',
                      style: TextStyle(
                        color: _colorController.textColor.value,
                      ),
                    ),
                  );
                }

                final searchQuery = _searchController.text.toLowerCase();
                var filteredHymns = searchQuery.isEmpty
                    ? _sortHymns(List<Hymn>.from(hymns))
                    : _sortHymns(
                        hymns
                            .where((hymn) =>
                                hymn.hymnNumber
                                    .toLowerCase()
                                    .contains(searchQuery) ||
                                hymn.title
                                    .toLowerCase()
                                    .contains(searchQuery) ||
                                hymn.verses.any((verse) =>
                                    verse.toLowerCase().contains(searchQuery)))
                            .toList(),
                      );

                return ListView.builder(
                  itemCount: filteredHymns.length,
                  itemBuilder: (context, index) {
                    final hymn = filteredHymns[index];
                    return _buildHymnListItem(hymn, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
