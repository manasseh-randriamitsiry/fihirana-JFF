import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../widgets/context_aware_fab.dart';
import '../../widgets/recording/recording_tile_widget.dart';
import '../../widgets/hymn/hymn_search_field.dart';
import '../../widgets/empty_state_widget.dart';
import '../../services/core/security_service.dart';
import '../../models/user_recording.dart';
import '../../l10n/app_localizations.dart';
import 'standalone_recording_screen.dart';

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

  void _showDriveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Get.find<ColorController>().backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.cloud_done,
              color: Get.find<ColorController>().primaryColor.value,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Google Drive',
              style: TextStyle(
                color: Get.find<ColorController>().textColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signed in as:',
              style: TextStyle(
                color: Get.find<ColorController>()
                    .textColor
                    .value
                    .withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _recordingController.userEmail.value ?? 'Unknown',
              style: TextStyle(
                color: Get.find<ColorController>().textColor.value,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final quota = _recordingController.storageQuota.value;
              if (quota == null) {
                return const SizedBox.shrink();
              }

              final usage = quota['usage'] as int? ?? 0;
              final limit = quota['limit'] as int? ?? 1;
              final usageGB = (usage / (1024 * 1024 * 1024)).toStringAsFixed(2);
              final limitGB = (limit / (1024 * 1024 * 1024)).toStringAsFixed(2);
              final percent = (usage / limit).clamp(0.0, 1.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Usage',
                    style: TextStyle(
                      color: Get.find<ColorController>()
                          .textColor
                          .value
                          .withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 0.9
                          ? Colors.red
                          : Get.find<ColorController>().primaryColor.value,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$usageGB GB of $limitGB GB used',
                    style: TextStyle(
                      color: Get.find<ColorController>().textColor.value,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style:
                  TextStyle(color: Get.find<ColorController>().textColor.value),
            ),
          ),
          Obx(() => _recordingController.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _recordingController.syncFromDrive();
                  },
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(AppLocalizations.of(context)!.sync),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Get.find<ColorController>().primaryColor.value,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                )),
          ElevatedButton(
            onPressed: () {
              _recordingController.signOutFromDrive();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppLocalizations.of(context)!.signOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Obx(() {
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
              'Recordings',
              style: defaultTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: iconColor),
                tooltip: 'Refresh recordings',
                onPressed: () => _recordingController.refreshRecordings(),
              ),
              Obx(() {
                if (_recordingController.isDriveSignedIn.value) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.sync, color: iconColor),
                        tooltip: 'Sync from Google Drive',
                        onPressed: () => _recordingController.syncFromDrive(),
                      ),
                      IconButton(
                        icon: Icon(Icons.cloud_done, color: iconColor),
                        tooltip:
                            'Signed in as ${_recordingController.userEmail.value}',
                        onPressed: _showDriveDialog,
                      ),
                    ],
                  );
                } else {
                  return IconButton(
                    icon: Icon(Icons.cloud_upload_outlined, color: iconColor),
                    tooltip: 'Sign in to Google Drive',
                    onPressed: () => _recordingController.signInToDrive(),
                  );
                }
              }),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Obx(() {
                    final filteredRecordings = _getFilteredRecordings();
                    return Text(
                      '${filteredRecordings.length} recording${filteredRecordings.length == 1 ? '' : 's'} found',
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
                child: Obx(() {
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
                            'Access Restricted',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your account has been restricted from recording features.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
      }),
    );
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
