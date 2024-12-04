import 'dart:async';

import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:fihirana/utility/screen_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/hymn.dart';
import '../../utility/navigation_utility.dart';
import 'edit_hymn_screen.dart';
import '../../services/hymn_service.dart';
import '../../controller/color_controller.dart';
import '../../controller/history_controller.dart';

class HymnDetailScreen extends StatefulWidget {
  final String hymnId;

  const HymnDetailScreen({
    Key? key,
    required this.hymnId,
  }) : super(key: key);

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final double _baseFontSize = 16.0;
  final double _baseCountFontSize = 50.0;
  double _fontSize = 16.0;
  double _countFontSize = 50.0;
  bool _show = false;
  bool _showSlider = false;
  bool _isFavorite = false;
  String _favoriteStatus = '';
  final HymnService _hymnService = HymnService();
  final ColorController colorController = Get.find<ColorController>();
  late final HistoryController historyController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _hymnData;
  Hymn? _hymn;

  @override
  void initState() {
    super.initState();
    // Initialize history controller if not already initialized
    if (!Get.isRegistered<HistoryController>()) {
      Get.put(HistoryController());
    }
    historyController = Get.find<HistoryController>();
    _loadFontSize();
    _loadHymnData();
    // Ensure favorites are synced when screen opens
    _hymnService.checkPendingSyncs();
  }

  void _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? _baseFontSize;
      _countFontSize = prefs.getDouble('countFontSize') ?? _baseCountFontSize;
    });
  }

  Future<void> _loadHymnData() async {
    try {
      final doc = await _firestore.collection('hymns').doc(widget.hymnId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('Loaded hymn data: $data'); // Debug log

        // Safely extract verses list
        List<String> verses = [];
        if (data['verses'] != null) {
          try {
            verses = List<String>.from(data['verses']);
          } catch (e) {
            print('Error parsing verses: $e');
          }
        }

        // Safely get timestamp
        DateTime createdAt = DateTime.now();
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is DateTime) {
            createdAt = data['createdAt'] as DateTime;
          }
        }

        setState(() {
          _hymnData = data;
          _hymn = Hymn(
            id: widget.hymnId,
            hymnNumber: data['hymnNumber']?.toString() ?? '',
            title: data['title']?.toString() ?? '',
            verses: verses,
            hymnHint: data['hint']?.toString(),
            bridge: data['bridge']?.toString(),
            createdAt: createdAt,
            createdBy: data['createdBy']?.toString() ?? '',
            createdByEmail: data['createdByEmail']?.toString(),
          );
          print('Hymn number loaded: ${_hymn?.hymnNumber}'); // Debug log
        });

        // Add to history after loading hymn data
        if (_hymn != null) {
          if (kDebugMode) {
            print(
                'Adding hymn to history: ${_hymn!.title} (${_hymn!.hymnNumber})');
          }
          await historyController.addToHistory(
            widget.hymnId,
            _hymn!.title,
            _hymn!.hymnNumber,
          );
          if (kDebugMode) {
            print('Successfully added to history');
          }
        } else {
          if (kDebugMode) {
            print('Error: Hymn object is null after loading data');
          }
        }

        _checkFavoriteStatus();
      } else {
        if (kDebugMode) {
          print('Error: Document does not exist for hymn ID: ${widget.hymnId}');
        }
      }
    } catch (e, stackTrace) {
      print('Error loading hymn data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await _hymnService.getFavoriteStatusStream().first;
    if (mounted) {
      setState(() {
        _isFavorite = status.containsKey(widget.hymnId);
        _favoriteStatus = status[widget.hymnId] ?? '';
      });
    }
  }

  Future<void> toggleFavorite() async {
    if (_hymn == null) return;

    // Optimistically update the UI
    final wasIsFavorite = _isFavorite;
    final wasFavoriteStatus = _favoriteStatus;

    setState(() {
      _isFavorite = !_isFavorite;
      if (_isFavorite) {
        _favoriteStatus =
            FirebaseAuth.instance.currentUser == null ? 'local' : 'cloud';
      } else {
        _favoriteStatus = '';
      }
    });

    try {
      // Perform the actual toggle
      await _hymnService.toggleFavorite(_hymn!);

      // If user is not logged in, show a snackbar suggesting to login for cloud sync
      if (FirebaseAuth.instance.currentUser == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Midira mba hahafahana mitahiry ny hira tianao any @ cloud'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Refresh the actual status
      _checkFavoriteStatus();
    } catch (e) {
      // Revert the state if there was an error
      setState(() {
        _isFavorite = wasIsFavorite;
        _favoriteStatus = wasFavoriteStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nisy olana ny fanovana ny fanitiavana ny hira'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToEditScreen(BuildContext context) {
    if (_hymn == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHymnScreen(hymn: _hymn!),
      ),
    );
  }

  List<Color> verseColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lime,
    Colors.cyan,
    Colors.brown,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Get.to(HomeScreen());
              },
              icon: Icon(
                Icons.arrow_back_ios_outlined,
                color: colorController.iconColor.value,
              )),
          backgroundColor: colorController.backgroundColor.value,
          centerTitle: true,
          title: GestureDetector(
            child: SizedBox(
              width: getScreenWidth(context) / 4,
              child: Text(
                _hymn?.hymnNumber ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorController.iconColor.value,
                  fontWeight: FontWeight.bold,
                  fontSize: _fontSize,
                ),
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return HymnSearchPopup(
                    colorController: colorController,
                    onHymnSelected: (selectedHymn) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HymnDetailScreen(hymnId: selectedHymn.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite
                    ? (_favoriteStatus == 'cloud' ? Colors.red : Colors.blue)
                    : colorController.iconColor.value,
              ),
              onPressed: toggleFavorite,
            ),
            PopupMenuButton<String>(
              color: colorController.primaryColor.value,
              icon: Icon(
                Icons.menu_sharp,
                color: colorController.iconColor.value,
              ),
              onSelected: (String item) {
                switch (item) {
                  case 'edit':
                    _navigateToEditScreen(
                      context,
                    );
                    break;
                  case 'switch_value':
                    setState(() {
                      _show = !_show;
                    });
                    break;
                  case 'font_size':
                    setState(() {
                      _showSlider = !_showSlider;
                    });
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  if (isUserAuthenticated())
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: colorController.iconColor.value,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hanova',
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'switch_value',
                    child: Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye,
                          color: colorController.iconColor.value,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Naoty',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'font_size',
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: colorController.iconColor.value,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Haben'ny soratra",
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: Text(
                  _hymn?.title ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    color: colorController.textColor.value,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_showSlider)
                Slider(
                  value: _fontSize,
                  min: 12,
                  max: 40,
                  divisions: 28,
                  label: _fontSize.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _fontSize = value;
                      _countFontSize =
                          value * (_baseCountFontSize / _baseFontSize);
                    });
                  },
                  onChangeEnd: (double value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble('fontSize', value);
                    setState(() {
                      _showSlider = false; // Hide the slider on release
                    });
                  },
                ),
              if (_show &&
                  (_hymn?.hymnHint?.trim().toLowerCase().isNotEmpty ??
                      false)) ...[
                if (isUserAuthenticated())
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          colorController.primaryColor.value.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nampiditra: ${_hymn?.createdBy}',
                          style: TextStyle(
                            fontSize: _fontSize * 0.8,
                            color: colorController.textColor.value,
                          ),
                        ),
                        if (_hymn?.createdByEmail != null)
                          Text(
                            'Email: ${_hymn?.createdByEmail}',
                            style: TextStyle(
                              fontSize: _fontSize * 0.8,
                              color: colorController.textColor.value,
                            ),
                          ),
                        Text(
                          'Daty: ${DateFormat('dd/MM/yyyy HH:mm').format(_hymn?.createdAt ?? DateTime(2023))}',
                          style: TextStyle(
                            fontSize: _fontSize * 0.8,
                            color: colorController.textColor.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    _hymn?.hymnHint ?? '', // Provide default value if null
                    style: TextStyle(
                      fontSize: 2 * _fontSize / 3,
                      color: colorController.textColor.value,
                    ),
                  ),
                ),
              ],
              if (_hymn?.bridge != null &&
                  (_hymn?.bridge?.trim().toLowerCase().isNotEmpty ??
                      false)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 15),
                  child: Text(
                    'Isan\'andininy:',
                    style: TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                  child: Text(
                    _hymn?.bridge ?? '',
                    style: TextStyle(
                        fontSize: _fontSize,
                        color: colorController.textColor.value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(
                    'Andininy',
                    style: TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                ),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < (_hymn?.verses?.length ?? 0); i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 30.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.15,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: _countFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorController.primaryColor.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: Text(
                              '${i + 1}. ${_hymn?.verses?[i] ?? ''}',
                              style: TextStyle(
                                fontSize: _fontSize,
                                color: verseColors[i % verseColors.length],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HymnSearchPopup extends StatefulWidget {
  final ColorController colorController;
  final Function(Hymn) onHymnSelected;

  const HymnSearchPopup({
    Key? key,
    required this.colorController,
    required this.onHymnSelected,
  }) : super(key: key);

  @override
  State<HymnSearchPopup> createState() => _HymnSearchPopupState();
}

class _HymnSearchPopupState extends State<HymnSearchPopup> {
  final TextEditingController _searchController = TextEditingController();
  final HymnService _hymnService = HymnService();
  String _searchQuery = '';
  List<Hymn> _cachedHymns = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: widget.colorController.backgroundColor.value,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: widget.colorController.textColor.value,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hikaroka...',
                        hintStyle: TextStyle(
                          color: widget.colorController.textColor.value
                              .withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: widget.colorController.iconColor.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: widget.colorController.textColor.value,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: widget.colorController.textColor.value,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: widget.colorController.primaryColor.value,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: widget.colorController.iconColor.value,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: StreamBuilder<QuerySnapshot>(
                stream: _hymnService.getHymnsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedHymns.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: widget.colorController.primaryColor.value,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Misy olana: ${snapshot.error}',
                        style: TextStyle(
                          color: widget.colorController.textColor.value,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Tsy misy hira hita',
                        style: TextStyle(
                          color: widget.colorController.textColor.value,
                        ),
                      ),
                    );
                  }

                  final hymns = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Hymn(
                      id: doc.id,
                      hymnNumber: data['hymnNumber'].toString(),
                      title: data['title'] as String,
                      verses:
                          List<String>.from(data['verses'] as List<dynamic>),
                      bridge: data['bridge'] as String?,
                      hymnHint: data['hymnHint'] as String?,
                      createdAt: data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp).toDate()
                          : DateTime(2023),
                      createdBy: data['createdBy'] as String? ?? 'Unknown',
                      createdByEmail: data['createdByEmail'] as String?,
                    );
                  }).toList();

                  _cachedHymns = hymns;
                  final filteredHymns = _filterHymns(hymns);

                  if (filteredHymns.isEmpty) {
                    return Center(
                      child: Text(
                        'Tsy misy hira mifanaraka amin\'ny fikarohana',
                        style: TextStyle(
                          color: widget.colorController.textColor.value,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredHymns.length,
                    itemBuilder: (context, index) {
                      final hymn = filteredHymns[index];
                      return ListTile(
                        title: Text(
                          '${hymn.hymnNumber} - ${hymn.title}',
                          style: TextStyle(
                            color: widget.colorController.textColor.value,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          hymn.verses.first.substring(
                                0,
                                hymn.verses.first.length > 50
                                    ? 50
                                    : hymn.verses.first.length,
                              ) +
                              '...',
                          style: TextStyle(
                            color: widget.colorController.textColor.value
                                .withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          NavigationUtility.navigateToDetailScreen(
                              context, hymn);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Hymn> _filterHymns(List<Hymn> hymns) {
    if (_searchQuery.isEmpty) return hymns;

    final lowercaseQuery = _searchQuery.toLowerCase();
    return hymns.where((hymn) {
      return hymn.hymnNumber.toLowerCase().contains(lowercaseQuery) ||
          hymn.title.toLowerCase().contains(lowercaseQuery) ||
          hymn.verses
              .any((verse) => verse.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
