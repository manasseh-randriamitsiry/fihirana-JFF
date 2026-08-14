import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/hymn/presentation/controllers/hymn_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/recording/presentation/widgets/recording_controls_widget.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_search_field.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_list_item.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/empty_state_widget.dart';
import 'package:fihirana/shared/widgets/common/skeleton_hymn_list.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class StandaloneRecordingScreen extends StatefulWidget {
  const StandaloneRecordingScreen({super.key});

  @override
  State<StandaloneRecordingScreen> createState() =>
      _StandaloneRecordingScreenState();
}

class _StandaloneRecordingScreenState extends State<StandaloneRecordingScreen> {
  final RecordingController _controller = Get.find<RecordingController>();
  final HymnController _hymnController = Get.find<HymnController>();
  final TextEditingController _nameController = TextEditingController();

  String _recordingTitle = '';
  bool _showHymnList = false;

  @override
  void initState() {
    super.initState();
    _initializeRecordingName();
    // Ensure overlay is hidden when entering standalone recording
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.hideOverlay();
      // Initialize recording service
      _controller.onPageVisible();
      // Multiple checks to ensure overlay is hidden
      for (int i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: 100 * (i + 1)), () {
          if (mounted) {
            _controller.hideOverlay();
          }
        });
      }
    });
  }

  void _initializeRecordingName() {
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _recordingTitle = 'Enregistrement - $timestamp';
    _nameController.text = _recordingTitle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Don't call controller methods during dispose as they may trigger Obx updates
    // _controller.hideOverlay(); // Remove this to prevent Obx updates during disposal
    super.dispose();
  }

  void _startRecording() async {
    // Ensure we're not already recording and overlay is hidden
    if (_controller.isRecording.value) {
      Get.snackbar('Information', 'Un enregistrement est déjà en cours.');
      return;
    }

    _controller.hideOverlay();

    // Start recording without hymn context
    try {
      await _controller.startRecording('standalone');
    } catch (e) {
      if (mounted) {
        Get.snackbar('Erreur', 'Impossible de démarrer l’enregistrement : $e');
      }
    }
  }

  void _stopRecording() async {
    try {
      if (kDebugMode) {
        print('StandaloneRecording: Stopping recording...');
      }
      // Use current text from name controller instead of _recordingTitle
      final currentTitle = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : _recordingTitle;
      if (kDebugMode) {
        print('StandaloneRecording: Using title: "$currentTitle"');
        print(
            'StandaloneRecording: Name controller text: "${_nameController.text}"');
      }

      final recording =
          await _controller.stopRecording('standalone', currentTitle);
      if (kDebugMode) {
        print(
            'StandaloneRecording: Recording result title: ${recording?.title}');
        print('StandaloneRecording: Recording result: $recording');
      }
      if (recording != null && mounted) {
        _showSaveDialog();
      } else if (mounted && recording == null) {
        Get.snackbar('Erreur', 'Impossible d’enregistrer le fichier.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('StandaloneRecording: Error stopping recording: $e');
      }
      if (mounted) {
        Get.snackbar('Erreur', 'Impossible d’arrêter l’enregistrement : $e');
      }
    }
  }

  void _saveRecording() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
          'Erreur', 'Veuillez renseigner un nom pour l’enregistrement.');
      return;
    }

    // Close dialog first to prevent widget tree conflicts
    if (mounted) {
      Navigator.pop(context);
    }

    // Update recording name if user changed it after stopping recording
    try {
      final recordings = _controller.recordings;
      if (recordings.isNotEmpty) {
        final lastRecording = recordings.last;
        // Only rename if the name is different from current recording title
        if (lastRecording.title != name) {
          if (kDebugMode) {
            print(
                'StandaloneRecording: Renaming from "${lastRecording.title}" to "$name"');
          }
          await _controller.renameRecording(lastRecording, name);
        }
      }
    } catch (e) {
      debugPrint('Error renaming recording: $e');
    }

    // Navigate back after all operations are complete
    if (mounted) {
      // Add small delay to ensure widget tree is stable
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Get.back(); // Go back to previous screen
        }
      });
    }
  }

  void _discardRecording() {
    if (mounted) {
      Navigator.pop(context);
      Get.back(); // Go back to previous screen
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enregistrement terminé'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 42,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [],
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’enregistrement',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _discardRecording,
            child: const Text('Ignorer'),
          ),
          FilledButton(
            onPressed: _saveRecording,
            child: Text(AppLocalizations.of(dialogContext).save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = colors.onSurface;
    final backgroundColor = colors.surface;
    final iconColor = colors.onSurface;
    final defaultTextStyle = TextStyle(color: textColor, inherit: true);

    return Obx(() {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: iconColor),
            onPressed: () => Get.back(),
          ),
          title: const Text('Enregistrement'),
          actions: [
            IconButton(
              icon: Icon(
                _showHymnList
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: iconColor,
              ),
              onPressed: () {
                setState(() {
                  _showHymnList = !_showHymnList;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar for hymns
            if (_showHymnList)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: HymnSearchField(
                  controller: _hymnController.safeSearchController,
                  defaultTextStyle: defaultTextStyle,
                  textColor: textColor,
                  iconColor: iconColor,
                  backgroundColor: backgroundColor,
                  onChanged: () {
                    if (mounted && !_hymnController.isDisposed) {
                      setState(() {});
                    }
                  },
                ),
              ),

            // Recording title input
            if (!_showHymnList)
              AppSection(
                title: 'Détails',
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppGroupedSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [],
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l’enregistrement',
                        prefixIcon: Icon(Icons.edit_outlined),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

            // Content area - either hymn list or recording controls
            Expanded(
              child: _showHymnList
                  ? _buildHymnList(defaultTextStyle, textColor, backgroundColor,
                      colors.primary)
                  : _buildRecordingControls(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRecordingControls() {
    return SafeArea(
      child: AppSection(
        title: 'Commandes',
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: AppGroupedSurface(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          children: [
            Center(
              child: Obx(() {
                if (!mounted) return const SizedBox.shrink();
                return RecordingControlsWidget(
                  isRecording: _controller.isRecording.value,
                  isPaused: _controller.isPaused.value,
                  onStart: _startRecording,
                  onStop: _stopRecording,
                  onPause: () => _controller.pauseRecording(),
                  onResume: () => _controller.resumeRecording(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHymnList(TextStyle defaultTextStyle, Color textColor,
      Color backgroundColor, Color primaryColor) {
    return StreamBuilder<List<Hymn>>(
      stream: _hymnController.hymnsStream,
      builder: (context, snapshot) {
        // Early return if widget is not mounted
        if (!mounted) return const SizedBox.shrink();
        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.translate(
                  (l) => l.errorOccurredWithDetails(snapshot.error.toString())),
              style: defaultTextStyle,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonHymnList();
        }

        final hymns = _hymnController.filterHymnList(snapshot.data ?? []);
        if (hymns.isEmpty) {
          return EmptyStateWidget(
            message: context.translate((l) => l.noHymnsFound),
            icon: Icons.music_off_rounded,
            actionLabel: context.translate((l) => l.clearSearch),
            onActionPressed: () {
              if (!_hymnController.isDisposed) {
                _hymnController.safeSearchController.clear();
                setState(() {});
              }
            },
          );
        }

        return ListView.builder(
          key: const PageStorageKey('standalone_recordings_hymns_list'),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            return HymnListItem(
              key: ValueKey(hymn.id),
              hymn: hymn,
              textColor: textColor,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
              onFavoritePressed: () => _hymnController.toggleFavorite(hymn),
              onMusicPressed: () {
                // Set the recording name to the selected hymn title
                setState(() {
                  _nameController.text = hymn.title;
                  _showHymnList = false;
                });
              },
            );
          },
        );
      },
    );
  }
}
