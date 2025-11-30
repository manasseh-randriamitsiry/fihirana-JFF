import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import 'package:fihirana/services/features/hymn_service.dart';
import 'package:fihirana/services/audio/audio_service.dart';
import '../../widgets/player/lightweight_audio_player_widget.dart';
import '../../widgets/hymn/hymn_form_widgets.dart';

import '../../controller/shell_controller.dart';
import '../../l10n/app_localizations.dart';

class CreateHymnPage extends StatefulWidget {
  const CreateHymnPage({super.key});

  @override
  CreateHymnPageState createState() => CreateHymnPageState();
}

class CreateHymnPageState extends State<CreateHymnPage> {
  final _formKey = GlobalKey<FormState>();
  final _hymnNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _bridgeController = TextEditingController();
  final _hymnHintController = TextEditingController();
  final List<TextEditingController> _verseControllers = [
    TextEditingController()
  ];
  final _debouncer = Debouncer(milliseconds: 500);
  final AudioService _audioService = AudioService.instance;
  bool _hasAudio = false;
  bool _audioChecked = false;

  @override
  void dispose() {
    _hymnNumberController.dispose();
    _titleController.dispose();
    _bridgeController.dispose();
    _hymnHintController.dispose();
    for (var controller in _verseControllers) {
      controller.dispose();
    }
    _debouncer.dispose();
    super.dispose();
  }

  void _clearForm() {
    if (!mounted) return;

    setState(() {
      _hymnNumberController.text = '';
      _titleController.text = '';
      for (var controller in _verseControllers) {
        controller.text = '';
      }

      while (_verseControllers.length > 1) {
        _verseControllers.removeLast();
      }
      _bridgeController.text = '';
      _hymnHintController.text = '';
    });
  }

  Future<void> _createHymn() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Get.find<ColorController>().primaryColor.value,
          ),
        ),
      );

      final hymnNumber = _hymnNumberController.text.trim();
      final hymn = Hymn(
        id: '',
        hymnNumber: hymnNumber,
        title: _titleController.text.trim(),
        verses: _verseControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
        bridge: _bridgeController.text.trim(),
        hymnHint: _hymnHintController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: '',
        createdByEmail: '',
      );

      final success = await Get.find<HymnService>().addHymn(hymn);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        await _checkAudioAvailability(hymnNumber);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.hymnSavedSuccessfully,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorSavingHymn(error.toString()),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkAudioAvailability(String hymnNumber) async {
    final hasAudio = await _audioService.checkAudioFileExists(hymnNumber);
    if (mounted) {
      setState(() {
        _hasAudio = hasAudio;
        _audioChecked = true;
      });
    }
  }

  void _showAudioPlayerDialog() {
    final l10n = AppLocalizations.of(context)!;
    if (_hymnNumberController.text.trim().isEmpty) return;

    final hymn = Hymn(
      id: '',
      hymnNumber: _hymnNumberController.text.trim(),
      title: _titleController.text.trim().isEmpty
          ? l10n.newHymn
          : _titleController.text.trim(),
      verses: [],
      createdAt: DateTime.now(),
      createdBy: '',
      createdByEmail: '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Get.find<ColorController>().backgroundColor.value,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.audioPlayer,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Get.find<ColorController>().textColor.value,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Get.find<ColorController>().iconColor.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LightweightAudioPlayerWidget(
                  hymn: hymn,
                  isCompact: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authController = Get.find<AuthController>();
    final user = FirebaseAuth.instance.currentUser;

    // Check permissions:
    // 1. If admin, always allow
    // 2. If canAddSongs is true AND (remainingHymnsThisMonth > 0 OR admin), allow
    // 3. Otherwise, show restriction message

    bool isAllowed = authController.isAdmin ||
        (authController.canAddSongs &&
            authController.remainingHymnsThisMonth > 0);

    if (!isAllowed) {
      String message;
      if (authController.canAddSongs &&
          authController.remainingHymnsThisMonth <= 0) {
        message = "5 ihany no hira afaka ampidirina isambolana.";
      } else {
        message = l10n.noPermissionToCreate(user?.email ?? '');
      }

      return Scaffold(
        backgroundColor: Get.find<ColorController>().backgroundColor.value,
        appBar: AppBar(
          backgroundColor: Get.find<ColorController>().backgroundColor.value,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.createHymn,
            style: TextStyle(
              color: Get.find<ColorController>().textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Get.find<ColorController>().iconColor.value,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Get.find<ColorController>().backgroundColor.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Get.find<ColorController>()
                        .iconColor
                        .value
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: Get.find<ColorController>().textColor.value,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              color: colorController.iconColor.value,
            ),
            onPressed: () => Get.find<ShellController>().toggleDrawer(),
          ),
          title: Text(
            l10n.addHymn,
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!authController.isAdmin)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorController.primaryColor.value
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorController.primaryColor.value
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorController.primaryColor.value,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hymns remaining this month: ${authController.remainingHymnsThisMonth}',
                              style: TextStyle(
                                color: colorController.textColor.value,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  FormTextFieldWidget(
                    controller: _hymnNumberController,
                    label: l10n.number,
                    keyboardType: TextInputType.number,
                    icon: Icons.tag,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterHymnNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  FormTextFieldWidget(
                    controller: _titleController,
                    label: l10n.title,
                    icon: Icons.title,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterTitle;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Verses Section Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: colorController.primaryColor.value,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.verses,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: colorController.textColor.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _verseControllers.removeAt(oldIndex);
                        _verseControllers.insert(newIndex, item);
                      });
                    },
                    children: List.generate(_verseControllers.length, (index) {
                      return VerseFieldWidget(
                        key: ValueKey('verse_$index'),
                        index: index,
                        controller: _verseControllers[index],
                        onDelete: () {
                          setState(() {
                            _verseControllers[index].dispose();
                            _verseControllers.removeAt(index);
                          });
                        },
                        onChanged: () {
                          _debouncer.run(() {
                            setState(() {});
                          });
                        },
                      );
                    }),
                  ),

                  // Add Verse Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _verseControllers.add(TextEditingController());
                        });
                      },
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: colorController.primaryColor.value,
                      ),
                      label: Text(
                        l10n.addVerse,
                        style: TextStyle(
                          color: colorController.primaryColor.value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: colorController.primaryColor.value
                              .withValues(alpha: 0.5),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  FormTextFieldWidget(
                    controller: _bridgeController,
                    label: l10n.bridgeOptional,
                    maxLines: 3,
                    icon: Icons.repeat,
                  ),
                  const SizedBox(height: 16.0),

                  FormTextFieldWidget(
                    controller: _hymnHintController,
                    label: l10n.hymnHint,
                    maxLines: 2,
                    icon: Icons.lightbulb_outline,
                  ),

                  // Audio availability indicator
                  if (_audioChecked)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _hasAudio
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasAudio ? Colors.green : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasAudio ? Icons.music_note : Icons.music_off,
                              color: _hasAudio ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _hasAudio
                                    ? l10n.audioAvailable
                                    : l10n.noAudioAvailable,
                                style: TextStyle(
                                  color: _hasAudio ? Colors.green : Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_hasAudio)
                              IconButton(
                                onPressed: _showAudioPlayerDialog,
                                icon: Icon(
                                  Icons.play_circle_outline,
                                  color: colorController.primaryColor.value,
                                  size: 28,
                                ),
                                tooltip: l10n.playAudio,
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24.0),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _createHymn();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorController.primaryColor.value,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: colorController.primaryColor.value
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.submit,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
