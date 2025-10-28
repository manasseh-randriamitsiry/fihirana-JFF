import 'dart:async';
import 'package:fihirana/utility/screen_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../models/hymn.dart';
import 'edit_hymn_screen.dart';
import '../../services/hymn_service.dart';
import '../../controller/color_controller.dart';
import '../../controller/history_controller.dart';

class HymnDetailScreen extends StatefulWidget {
  final String hymnId;

  const HymnDetailScreen({
    super.key,
    required this.hymnId,
  });

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final double _baseFontSize = 16.0;
  final double _baseCountFontSize = 50.0;
  double _fontSize = 16.0;
  double _countFontSize = 50.0;
  bool _show = true;
  bool _showSlider = false;
  final HymnService _hymnService = HymnService();
  final ColorController colorController = Get.find<ColorController>();
  late final HistoryController historyController;
  Hymn? _hymn;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<HistoryController>()) {
      Get.put(HistoryController());
    }
    historyController = Get.find<HistoryController>();
    _loadFontSize();
    _loadHymnData();

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
      final hymn = await _hymnService.getHymnById(widget.hymnId);
      if (hymn != null) {
        setState(() {
          _hymn = hymn;
        });

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
        }
      } else {
        if (kDebugMode) {
        }
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Get.back();
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
            StreamBuilder<Map<String, String>>(
              stream: _hymnService.getFavoriteStatusStream(),
              builder: (context, snapshot) {
                final favoriteStatus = snapshot.data?[widget.hymnId] ?? '';
                final isFavorite = favoriteStatus.isNotEmpty;

                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? (favoriteStatus == 'cloud' ? Colors.red : Colors.blue)
                        : colorController.iconColor.value,
                  ),
                  onPressed: () {
                    if (_hymn != null) {
                      _hymnService.toggleFavorite(_hymn!);
                    }
                  },
                );
              },
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
                  if (canEditHymn())
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: colorController.iconColor.value,
                          ),
                          const SizedBox(width: 8),
                          const Text(
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
                        const Text(
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
                        const Text(
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
        body: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [

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

                  if (isFirebaseHymn() && _hymn != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorController.primaryColor.value.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Hira avy amin\'ny fihirana fanampiny',
                        style: TextStyle(
                          fontSize: _fontSize * 0.8,
                          color: colorController.textColor.value,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  if (isFirebaseHymn() && _hymn != null)
                    StreamBuilder(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = FirebaseAuth.instance.currentUser;
                        final isAdmin = user?.email == 'manassehrandriamitsiry@gmail.com';

                        if (isAdmin) {
                          return Text(
                            'Nampiditra: ${_hymn!.createdBy}${_hymn!.createdByEmail != null ? ' (${_hymn!.createdByEmail})' : ''}',
                            style: TextStyle(
                              fontSize: _fontSize * 0.8,
                              color: colorController.textColor.value.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 8),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_hymn?.bridge != null &&
                              (_hymn?.bridge?.trim().toLowerCase().isNotEmpty ??
                                  false))
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _show = !_show;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Isan\'andininy:',
                                          style: TextStyle(
                                            fontSize: _fontSize + 2,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colorController.textColor.value,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _show
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color:
                                              colorController.iconColor.value,
                                        ),
                                      ],
                                    ),
                                    if (_show)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _hymn?.bridge ?? '',
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            color:
                                                colorController.textColor.value,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
                          _showSlider = false;
                        });
                      },
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_show &&
                        (_hymn?.hymnHint?.trim().toLowerCase().isNotEmpty ??
                            false)) ...[
                      if (isUserAuthenticated())
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorController.primaryColor.value
                                .withOpacity(0.5),
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
                          _hymn?.hymnHint ?? '',
                          style: TextStyle(
                            fontSize: 2 * _fontSize / 3,
                            color: colorController.textColor.value,
                          ),
                        ),
                      ),
                    ],
                    for (int i = 0; i < (_hymn?.verses.length ?? 0); i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 30.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.25,
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
                                '${i + 1}. ${_hymn?.verses[i] ?? ''}',
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  color: colorController.textColor.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                      height: getScreenHeight(context) / 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  bool isFirebaseHymn() {
    if (_hymn == null) return false;

    return _hymn!.createdByEmail != null && _hymn!.createdBy != 'Local File';
  }

  bool canEditHymn() {
    if (!isUserAuthenticated() || !isFirebaseHymn() || _hymn == null) return false;

    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == 'manassehrandriamitsiry@gmail.com';
    final isCreator = _hymn!.createdByEmail == user?.email;

    return isAdmin || isCreator;
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
}

class HymnSearchPopup extends StatefulWidget {
  final ColorController colorController;
  final Function(Hymn) onHymnSelected;

  const HymnSearchPopup({
    super.key,
    required this.colorController,
    required this.onHymnSelected,
  });

  @override
  State<HymnSearchPopup> createState() => _HymnSearchPopupState();
}

class _HymnSearchPopupState extends State<HymnSearchPopup> {
  final HymnService _hymnService = HymnService();
  List<Hymn> _hymns = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHymns();
  }

  Future<void> _loadHymns() async {
    try {
      final hymns = await _hymnService.searchHymns('');
      setState(() {
        _hymns = hymns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchHymns(String query) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final hymns = await _hymnService.searchHymns(query);
        setState(() {
          _hymns = hymns;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.colorController.backgroundColor.value,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Karoka hira...',
                hintStyle: TextStyle(
                  color: widget.colorController.textColor.value.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.colorController.textColor.value,
                ),
              ),
              style: TextStyle(
                color: widget.colorController.textColor.value,
              ),
              onChanged: _searchHymns,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hymns.isEmpty
                      ? Center(
                          child: Text(
                            'Tsy misy hira',
                            style: TextStyle(
                              color: widget.colorController.textColor.value,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _hymns.length,
                          itemBuilder: (context, index) {
                            final hymn = _hymns[index];
                            return ListTile(
                              title: Text(
                                '${hymn.hymnNumber} - ${hymn.title}',
                                style: TextStyle(
                                  color: widget.colorController.textColor.value,
                                ),
                              ),
                              onTap: () {
                                widget.onHymnSelected(hymn);
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
}