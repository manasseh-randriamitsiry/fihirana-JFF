import 'dart:async';
import 'package:fihirana/utility/screen_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import 'edit_hymn_screen.dart';
import '../../services/hymn_service.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/history_controller.dart';
import '../../controller/auth_controller.dart';
import '../../l10n/app_localizations.dart';

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
  bool _showNote = true;
  final HymnService _hymnService = HymnService();
  final NoteService _noteService = NoteService();
  final AuthController _authController = Get.find<AuthController>();
  final ColorController colorController = Get.find<ColorController>();
  late final HistoryController historyController;
  Hymn? _hymn;
  Note? _userNote;
  bool _isLoadingNote = true;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<HistoryController>()) {
      Get.put(HistoryController());
    }
    historyController = Get.find<HistoryController>();
    _loadFontSize();
    _loadHymnData();
    _loadUserNote();

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
        if (kDebugMode) {}
      } else {
        if (kDebugMode) {}
      }
    } catch (e) {}
  }

  Future<void> _loadUserNote() async {
    if (!isUserAuthenticated()) {
      setState(() {
        _isLoadingNote = false;
      });
      return;
    }

    try {
      final note = await _noteService.getNote(widget.hymnId);
      setState(() {
        _userNote = note;
        _isLoadingNote = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user note: $e');
      }
      setState(() {
        _isLoadingNote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  case 'add_note':
                    _showNoteEditor();
                    break;
                  case 'toggle_note':
                    setState(() {
                      _showNote = !_showNote;
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
                          Text(
                            l10n.edit,
                          ),
                        ],
                      ),
                    ),
                  if (isUserAuthenticated())
                    PopupMenuItem<String>(
                      value: 'add_note',
                      child: Row(
                        children: [
                          Icon(
                            _userNote != null
                                ? Icons.edit_note
                                : Icons.note_add,
                            color: colorController.iconColor.value,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _userNote != null ? l10n.editNote : l10n.add,
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
                          l10n.font,
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
                  if (isFirebaseHymn() && _hymn != null)
                    StreamBuilder(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = FirebaseAuth.instance.currentUser;
                        final isAdmin =
                            user?.email == 'manassehrandriamitsiry@gmail.com';

                        if (isAdmin) {
                          return Text(
                            l10n.createdBy(_hymn!.createdBy +
                                (_hymn!.createdByEmail != null
                                    ? ' (${_hymn!.createdByEmail})'
                                    : '')),
                            style: TextStyle(
                              fontSize: _fontSize * 0.8,
                              color: colorController.textColor.value
                                  .withOpacity(0.7),
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
                      color: colorController.backgroundColor.value,
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
                                          l10n.everyVerseChorus,
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
                    if (isUserAuthenticated() && _hymn != null)
                      StreamBuilder<List<Note>>(
                        stream: _noteService.getPublicNotesStream(_hymn!.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading notes'));
                          }

                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final notes = snapshot.data!;

                          if (notes.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: notes.length,
                                itemBuilder: (context, index) {
                                  final note = notes[index];
                                  return FutureBuilder<bool>(
                                    future: _noteService.canEditNote(note),
                                    builder: (context, snapshot) {
                                      final canEdit = snapshot.data ?? false;

                                      return Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorController
                                              .backgroundColor.value
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  note.content,
                                                  style: TextStyle(
                                                    fontSize: _fontSize * 0.9,
                                                    color: colorController
                                                        .textColor.value,
                                                  ),
                                                ),
                                                if (canEdit)
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      size: _fontSize,
                                                      color: colorController
                                                          .iconColor.value,
                                                    ),
                                                    onPressed: () =>
                                                        _showNoteEditor(
                                                            note: note),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
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
    if (!isUserAuthenticated() || !isFirebaseHymn() || _hymn == null)
      return false;

    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == 'manassehrandriamitsiry@gmail.com';
    final isCreator = _hymn!.createdByEmail == user?.email;

    return isAdmin || isCreator;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showNoteEditor({Note? note}) {
    if (!isUserAuthenticated()) return;

    final noteController =
        TextEditingController(text: note?.content ?? _userNote?.content ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              color: colorController.backgroundColor.value,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note != null ? 'Hanova naoty' : 'Ny naoty manokana',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorController.textColor.value,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorController.iconColor.value,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ampidiro eto ny naoty momba ny hira, toy ny akordy, fampahalalam-bavaka na fampahalalana hafa.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorController.textColor.value.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Soraty eto ny naotinao...',
                      hintStyle: TextStyle(
                        color: colorController.textColor.value.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              colorController.textColor.value.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              colorController.textColor.value.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorController.primaryColor.value,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: colorController.textColor.value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (note != null || _userNote != null)
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    colorController.backgroundColor.value,
                                title: Text(
                                  'Hamafa ny naoty?',
                                  style: TextStyle(
                                      color: colorController.textColor.value),
                                ),
                                content: Text(
                                  'Tena te hamafa ny naoty ve ianao?',
                                  style: TextStyle(
                                      color: colorController.textColor.value),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      'Tsia',
                                      style: TextStyle(
                                          color:
                                              colorController.textColor.value),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Eny',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              if (note != null) {
                                await _noteService.deleteNote(note.id);
                              } else {
                                await _noteService.deleteNote(_userNote!.id);
                                setState(() {
                                  _userNote = null;
                                });
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.noteDeleted),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final content = noteController.text.trim();
                          if (content.isEmpty) {
                            if (note != null) {
                              await _noteService.deleteNote(note.id);
                            } else if (_userNote != null) {
                              await _noteService.deleteNote(_userNote!.id);
                              setState(() {
                                _userNote = null;
                              });
                            }
                          } else {
                            final success = await _noteService.saveNote(
                                widget.hymnId, content);
                            if (success) {
                              if (note == null) {
                                await _loadUserNote();
                              }
                            }
                          }

                          if (context.mounted) {
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  content.isEmpty
                                      ? l10n.noteDeleted
                                      : l10n.noteSaved,
                                ),
                                backgroundColor:
                                    content.isEmpty ? Colors.red : Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorController.primaryColor.value,
                          foregroundColor:
                              colorController.backgroundColor.value,
                        ),
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    final l10n = AppLocalizations.of(context)!;
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
                hintText: l10n.searchHymns,
                hintStyle: TextStyle(
                  color:
                      widget.colorController.textColor.value.withOpacity(0.7),
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
                            l10n.noHymnsFound,
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
