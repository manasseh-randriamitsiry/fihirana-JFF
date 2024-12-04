import 'dart:async';

import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:fihirana/utility/screen_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;

  const HymnDetailScreen({super.key, required this.hymn});

  @override
  HymnDetailScreenState createState() => HymnDetailScreenState();
}

class HymnDetailScreenState extends State<HymnDetailScreen> {
  final double _baseFontSize = 16.0;
  final double _baseCountFontSize = 50.0;
  double _fontSize = 16.0;
  double _countFontSize = 50.0;
  double _scale = 1.0;
  bool _isFavorite = false;
  String _favoriteStatus = '';
  final HymnService _hymnService = HymnService();
  final ColorController colorController = Get.find<ColorController>();

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _loadFavoriteStatus();
    // Ensure favorites are synced when screen opens
    _hymnService.checkPendingSyncs();
  }

  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? _baseFontSize;
      _countFontSize = _fontSize * (_baseCountFontSize / _baseFontSize);
      _scale = _fontSize / _baseFontSize;
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final status = await _hymnService.getFavoriteStatusStream().first;
    if (mounted) {
      setState(() {
        _isFavorite = status.containsKey(widget.hymn.id);
        _favoriteStatus = status[widget.hymn.id] ?? '';
      });
    }
  }

  bool _showSlider = false; // Initially hidden
  bool _show = false;
  void _showFontSizeDialog(BuildContext context) {
    setState(() {
      _showSlider = !_showSlider;
    });
  }

  void _switchValue(BuildContext context) {
    setState(() {
      _show = !_show;
    });
  }

  Future<void> _saveFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
  }

  Future<void> _toggleFavorite() async {
    try {
      // Update local state immediately for better UX
      setState(() {
        if (_isFavorite) {
          _isFavorite = false;
          _favoriteStatus = '';
        } else {
          _isFavorite = true;
          _favoriteStatus =
              FirebaseAuth.instance.currentUser != null ? 'cloud' : 'local';
        }
      });

      // Perform the actual toggle
      await _hymnService.toggleFavorite(widget.hymn);

      // If user is not logged in, show a snackbar suggesting to login for cloud sync
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

      // Refresh the actual status
      _loadFavoriteStatus();
    } catch (e) {
      // Revert the state if there was an error
      setState(() {
        _isFavorite = !_isFavorite;
        _favoriteStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tsy nahomby ny fitahirizana'),
            backgroundColor: Colors.red,
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

  void _navigateToEditScreen(BuildContext context, Hymn hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHymnScreen(hymn: hymn),
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
                widget.hymn.hymnNumber,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorController.textColor.value,
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
                              HymnDetailScreen(hymn: selectedHymn),
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
              onPressed: _toggleFavorite,
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
                      Hymn(
                        id: widget.hymn.id,
                        hymnNumber: widget.hymn.hymnNumber,
                        title: widget.hymn.title,
                        verses: widget.hymn.verses,
                        hymnHint: widget.hymn.hymnHint,
                        bridge: widget.hymn.bridge,
                        createdAt: widget.hymn.createdAt,
                        createdBy: widget.hymn.createdBy,
                        createdByEmail: widget.hymn.createdByEmail,
                      ),
                    );
                    break;
                  case 'switch_value':
                    _switchValue(context);
                    break;
                  case 'font_size':
                    _showFontSizeDialog(context);
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
                  widget.hymn.title,
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
                Container(
                  child: SfSlider(
                    min: 10.0,
                    max: 100.0,
                    interval: 5,
                    showTicks: true,
                    minorTicksPerInterval: 1,
                    onChanged: (dynamic value) {
                      _saveFontSize();
                      setState(() {
                        _fontSize = value;
                      });
                    },
                    onChangeEnd: (dynamic value) {
                      setState(() {
                        _showSlider = false; // Hide the slider on release
                      });
                    },
                    value: _fontSize,
                  ),
                ),
              if (_show &&
                  (widget.hymn.hymnHint?.trim().toLowerCase().isNotEmpty ??
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
                          'Nampiditra: ${widget.hymn.createdBy}',
                          style: TextStyle(
                            fontSize: _fontSize * 0.8,
                            color: colorController.textColor.value,
                          ),
                        ),
                        if (widget.hymn.createdByEmail != null)
                          Text(
                            'Email: ${widget.hymn.createdByEmail}',
                            style: TextStyle(
                              fontSize: _fontSize * 0.8,
                              color: colorController.textColor.value,
                            ),
                          ),
                        Text(
                          'Daty: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.hymn.createdAt)}',
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
                    widget.hymn.hymnHint ?? '', // Provide default value if null
                    style: TextStyle(
                      fontSize: 2 * _fontSize / 3,
                      color: colorController.textColor.value,
                    ),
                  ),
                ),
              ],
              if (widget.hymn.bridge != null &&
                  widget.hymn.bridge!.trim().toLowerCase().isNotEmpty) ...[
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
                    widget.hymn.bridge!,
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
                  for (int i = 0; i < widget.hymn.verses.length; i++) ...[
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
                              '${i + 1}. ${widget.hymn.verses[i]}',
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
