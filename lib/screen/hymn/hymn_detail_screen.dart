import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:intl/intl.dart'; // Import the intl package

import '../../models/hymn.dart';
import 'edit_hymn_screen.dart';
import '../../services/hymn_service.dart';

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

  final HymnService _hymnService = HymnService();

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? _baseFontSize;
      _countFontSize = _fontSize * (_baseCountFontSize / _baseFontSize);
      _scale = _fontSize / _baseFontSize;
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hymn.hymnNumber,
          maxLines: null,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: _fontSize,
          ),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<List<String>>(
            stream: _hymnService.getFavoriteHymnIdsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return IconButton(
                  icon: Icon(Icons.favorite_border, color: textColor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nisy olana: ${snapshot.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                );
              }

              final isFavorite = snapshot.data?.contains(widget.hymn.id) ?? false;
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : textColor,
                ),
                onPressed: () async {
                  try {
                    await _hymnService.toggleFavorite(widget.hymn);
                    
                    // If user is not logged in, show a snackbar suggesting to login for cloud sync
                    if (FirebaseAuth.instance.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voatahiry eto amin\'ny finday. Raha te-hitahiry any @ kaonty, dia midira'),
                          duration: Duration(seconds: 3),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tsy nahomby ny fitahirizana'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          ),
          PopupMenuButton<String>(
            color: theme.primaryColor,
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
                          color: theme.dividerColor,
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
        child: Padding(
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
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Creation info
              if (isUserAuthenticated())
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nampiditra: ${widget.hymn.createdBy}',
                        style: TextStyle(
                          fontSize: _fontSize * 0.8,
                          color: textColor,
                        ),
                      ),
                      if (widget.hymn.createdByEmail != null)
                        Text(
                          'Email: ${widget.hymn.createdByEmail}',
                          style: TextStyle(
                            fontSize: _fontSize * 0.8,
                            color: textColor,
                          ),
                        ),
                      Text(
                        'Daty: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.hymn.createdAt)}',
                        style: TextStyle(
                          fontSize: _fontSize * 0.8,
                          color: textColor,
                        ),
                      ),
                    ],
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    widget.hymn.hymnHint ?? '', // Provide default value if null
                    style: TextStyle(
                      fontSize: 2 * _fontSize / 3,
                      color:
                          theme.textTheme.bodyLarge?.color, // Null-aware access
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
                      color: theme.textTheme.bodyLarge?.color,
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
                        color: theme.textTheme.bodyLarge?.color),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(
                    'Andininy',
                    style: TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
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
                                    color: theme.primaryColor,
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
