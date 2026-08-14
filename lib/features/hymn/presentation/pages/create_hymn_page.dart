import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';

import 'package:fihirana/features/hymn/presentation/widgets/hymn_form_widgets.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

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
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
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
            content: Text(l10n.hymnSavedSuccessfully),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
          content: Text(l10n.errorSavingHymn(error.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
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
    final l10n = AppLocalizations.of(context);
    if (_hymnNumberController.text.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
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
    final l10n = AppLocalizations.of(context);
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

      return AppPageScaffold(
        title: l10n.createHymn,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: Get.back,
        ),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.createHymn,
          message: message,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
        title: Text(l10n.addHymn),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
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
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cantiques restants ce mois-ci : ${authController.remainingHymnsThisMonth}',
                            style: TextStyle(
                              color: colors.onSurface,
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
                const SizedBox(height: AppDimensions.md),
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
                const SizedBox(height: AppDimensions.lg),

                // Verses Section Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_list_numbered,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.verses,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Kept for compatibility with the Flutter SDK used in CI.
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
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
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _verseControllers.add(TextEditingController());
                      });
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: colors.primary,
                    ),
                    label: Text(
                      l10n.addVerse,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: colors.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                FormTextFieldWidget(
                  controller: _bridgeController,
                  label: l10n.bridgeOptional,
                  maxLines: 3,
                  icon: Icons.repeat,
                ),
                const SizedBox(height: AppDimensions.md),

                FormTextFieldWidget(
                  controller: _hymnHintController,
                  label: l10n.hymnHint,
                  maxLines: 2,
                  icon: Icons.lightbulb_outline,
                ),

                // Audio availability indicator
                if (_audioChecked)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppDimensions.md),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _hasAudio
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasAudio ? colors.primary : colors.outline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hasAudio ? Icons.music_note : Icons.music_off,
                            color: _hasAudio ? colors.primary : colors.outline,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _hasAudio
                                  ? l10n.audioAvailable
                                  : l10n.noAudioAvailable,
                              style: TextStyle(
                                color: _hasAudio
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
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
                                color: colors.primary,
                                size: 28,
                              ),
                              tooltip: l10n.playAudio,
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppDimensions.lg),

                // Submit Button
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _createHymn();
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
    );
  }
}
