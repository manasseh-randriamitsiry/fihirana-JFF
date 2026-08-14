import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/shared/widgets/navigation/context_aware_fab.dart';
import 'package:fihirana/features/recording/presentation/widgets/recording_tile_widget.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_search_field.dart';
import 'package:fihirana/shared/widgets/common/empty_state_widget.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'standalone_recording_screen.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class RecordingManagerScreen extends StatefulWidget {
  const RecordingManagerScreen({super.key});

  @override
  State<RecordingManagerScreen> createState() => _RecordingManagerScreenState();
}

class _RecordingManagerScreenState extends State<RecordingManagerScreen> {
  late final RecordingController _recordingController;
  final RxString _filterOption =
      'all'.obs; // all, personal, public, uploaded, not_uploaded
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers properly to avoid disposal issues
    _recordingController = Get.isRegistered<RecordingController>()
        ? Get.find<RecordingController>()
        : Get.put(RecordingController(), permanent: true);

    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordingController.onPageVisible();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserRecording> _getFilteredRecordings() {
    List<UserRecording> allRecordings = [];

    // Get recordings based on filter
    switch (_filterOption.value) {
      case 'personal':
        allRecordings =
            _recordingController.recordings.where((r) => !r.isPublic).toList();
        break;
      case 'public':
        allRecordings = _recordingController.publicRecordings.toList();
        break;
      case 'uploaded':
        allRecordings = _recordingController.recordings
            .where((r) => r.driveFileId != null)
            .toList();
        break;
      case 'not_uploaded':
        allRecordings = _recordingController.recordings
            .where((r) => r.driveFileId == null)
            .toList();
        break;
      default: // 'all'
        allRecordings = [
          ..._recordingController.recordings.where((r) => !r.isPublic),
          ..._recordingController.publicRecordings
        ];
    }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      allRecordings = allRecordings.where((recording) {
        return recording.title
                .toLowerCase()
                .contains(_searchQuery.value.toLowerCase()) ||
            (recording.userName
                    ?.toLowerCase()
                    .contains(_searchQuery.value.toLowerCase()) ??
                false) ||
            recording.hymnId.contains(_searchQuery.value);
      }).toList();
    }
    return allRecordings;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(builder: (colorController) {
      final textColor = colorController.textColor.value;
      final backgroundColor = colorController.backgroundColor.value;
      final iconColor = colorController.iconColor.value;
      final defaultTextStyle = TextStyle(color: textColor, inherit: true);

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            key: const ValueKey('menu_button'),
            icon: Icon(Icons.menu, color: iconColor),
            onPressed: () => Get.find<ShellController>().toggleDrawer(),
          ),
          title: Text(
            'Enregistrements',
            style: defaultTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
          actions: [
            // Multi-select mode buttons
            Obx(() {
              if (!_recordingController.isMultiSelectMode.value) {
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.checklist, color: iconColor),
                    tooltip: 'Tout sélectionner',
                    onPressed: () {
                      final filteredRecordings = _getFilteredRecordings();
                      _recordingController
                          .selectAllRecordings(filteredRecordings);
                    },
                  ),
                  if (_recordingController.selectedRecordingIds.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(Icons.clear_all, color: iconColor),
                      tooltip: 'Effacer la sélection',
                      onPressed: () => _recordingController.clearSelection(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Supprimer définitivement',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: backgroundColor,
                            title: Text(
                              'Supprimer définitivement',
                              style: TextStyle(color: textColor),
                            ),
                            content: Text(
                              'Voulez-vous vraiment supprimer définitivement ${_recordingController.selectedRecordingIds.length} enregistrement${_recordingController.selectedRecordingIds.length == 1 ? '' : 's'} ? Cette action est irréversible.',
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.8)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Annuler',
                                    style: TextStyle(color: textColor)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await _recordingController
                              .permanentlyDeleteSelectedRecordings();
                        }
                      },
                    ),
                  ],
                  IconButton(
                    icon: Icon(Icons.cancel, color: iconColor),
                    tooltip: 'Quitter la sélection multiple',
                    onPressed: () =>
                        _recordingController.disableMultiSelectMode(),
                  ),
                ],
              );
            }),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: HymnSearchField(
                controller: _searchController,
                defaultTextStyle: defaultTextStyle,
                textColor: textColor,
                iconColor: iconColor,
                backgroundColor: backgroundColor,
                onChanged: () {
                  if (mounted) {
                    _searchQuery.value = _searchController.text;
                    setState(() {});
                  }
                },
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Personal', 'personal'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Public', 'public'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Uploaded', 'uploaded'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Not Uploaded', 'not_uploaded'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Results count
            if (_searchQuery.value.isNotEmpty || _filterOption.value != 'all')
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                child: Obx(() {
                  final filteredRecordings = _getFilteredRecordings();
                  return Text(
                    '${filteredRecordings.length} enregistrement${filteredRecordings.length == 1 ? '' : 's'} trouvé${filteredRecordings.length == 1 ? '' : 's'}',
                    style: defaultTextStyle.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  );
                }),
              ),

            const SizedBox(height: 8),

            // Recordings list
            Expanded(
              child: Builder(builder: (context) {
                // Security check - prevent banned users from accessing recordings
                final SecurityService securityService =
                    SecurityService.instance;
                if (securityService.isSecurityChecked &&
                    securityService.isUserBlocked) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          size: 80,
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Accès restreint',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Votre compte n'a pas accès aux fonctions d'enregistrement.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                securityService.blockReason.isNotEmpty
                                    ? securityService.blockReason
                                    : 'Account suspended',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Obx(() {
                  final filteredRecordings = _getFilteredRecordings();

                  if (filteredRecordings.isEmpty) {
                    return EmptyStateWidget(
                      message: _searchQuery.value.isNotEmpty
                          ? 'No recordings found'
                          : 'No recordings yet',
                      icon: _searchQuery.value.isNotEmpty
                          ? Icons.search_off
                          : Icons.mic_off_rounded,
                      actionLabel: _searchQuery.value.isNotEmpty
                          ? 'Clear Search'
                          : 'Start Recording',
                      onActionPressed: () {
                        if (_searchQuery.value.isNotEmpty) {
                          _searchController.clear();
                          _searchQuery.value = '';
                          setState(() {});
                        } else {
                          Get.to(() => const StandaloneRecordingScreen());
                        }
                      },
                    );
                  }

                  return ListView.builder(
                    key: const PageStorageKey('recordings_list'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md),
                    itemCount: filteredRecordings.length,
                    itemBuilder: (context, index) {
                      final recording = filteredRecordings[index];
                      final isPublic = recording.isPublic;

                      return RecordingTileWidget(
                        key: ValueKey(recording.id),
                        recording: recording,
                        index: index,
                        isPublic: isPublic,
                      )
                          .animate()
                          .fadeIn(
                              duration: 400.ms,
                              delay: (50 * index).clamp(0, 500).ms)
                          .slideY(
                              begin: 0.2,
                              end: 0,
                              curve: Curves.easeOutQuad,
                              duration: 400.ms);
                    },
                  );
                });
              }),
            ),
          ],
        ),
        floatingActionButton: ContextAwareFAB(
          onStartRecording: () {
            // Navigate to standalone recording screen
            Get.to(() => const StandaloneRecordingScreen());
          },
        ),
      );
    });
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() => FilterChip(
          label: Text(
            label,
            style: TextStyle(
              color: _filterOption.value == value
                  ? Colors.white
                  : Get.find<ColorController>().textColor.value,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: _filterOption.value == value,
          onSelected: (isSelected) {
            _filterOption.value = isSelected ? value : 'all';
            setState(() {});
          },
          backgroundColor: Get.find<ColorController>().backgroundColor.value,
          selectedColor: Get.find<ColorController>().primaryColor.value,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: Get.find<ColorController>()
                .primaryColor
                .value
                .withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ));
  }
}
