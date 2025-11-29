import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/widgets/context_aware_fab.dart';
import 'package:fihirana/widgets/recording/recording_tile_widget.dart';
import 'package:fihirana/services/security_service.dart';
import 'package:fihirana/models/user_recording.dart';
import 'standalone_recording_screen.dart';

class RecordingManagerScreen extends StatelessWidget {
  const RecordingManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.find to get existing controller or create if not exists
    final RecordingController controller =
        Get.isRegistered<RecordingController>()
            ? Get.find<RecordingController>()
            : Get.put(RecordingController(), permanent: true);
    final ColorController colorController = Get.find<ColorController>();

    // Search and filter controllers
    final TextEditingController searchController = TextEditingController();
    final RxString searchQuery = ''.obs;
    final RxString filterOption = 'all'.obs; // all, personal, public, uploaded, not_uploaded

    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageVisible();
    });

    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageVisible();
    });

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.menu_rounded, color: colorController.iconColor.value),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
        title: Text(
          'Recordings',
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: colorController.iconColor.value,
            ),
            tooltip: 'Refresh recordings',
            onPressed: () => controller.refreshRecordings(),
          ),
          Obx(() {
            if (controller.isDriveSignedIn.value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.sync,
                      color: colorController.iconColor.value,
                    ),
                    tooltip: 'Sync from Google Drive',
                    onPressed: () => controller.syncFromDrive(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cloud_done,
                      color: colorController.iconColor.value,
                    ),
                    tooltip: 'Signed in as ${controller.userEmail.value}',
                    onPressed: () {
                      _showDriveDialog(context, controller, colorController);
                    },
                  ),
                ],
              );
            } else {
              return IconButton(
                icon: Icon(
                  Icons.cloud_upload_outlined,
                  color: colorController.iconColor.value,
                ),
                tooltip: 'Sign in to Google Drive',
                onPressed: () => controller.signInToDrive(),
              );
            }
          }),
        ],
      ),
body: Obx(() {
        // Security check - prevent banned users from accessing recordings
        final SecurityService securityService = SecurityService.instance;
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
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
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

        // Apply search and filter
        List<UserRecording> getFilteredRecordings() {
          List<UserRecording> allRecordings = [];
          
          // Get recordings based on filter
          switch (filterOption.value) {
            case 'personal':
              allRecordings = controller.recordings.where((r) => !r.isPublic).toList();
              break;
            case 'public':
              allRecordings = controller.publicRecordings.toList();
              break;
            case 'uploaded':
              allRecordings = controller.recordings.where((r) => r.driveFileId != null).toList();
              break;
            case 'not_uploaded':
              allRecordings = controller.recordings.where((r) => r.driveFileId == null).toList();
              break;
            default: // 'all'
              allRecordings = [...controller.recordings.where((r) => !r.isPublic), ...controller.publicRecordings];
          }

          // Apply search filter
          if (searchQuery.value.isNotEmpty) {
            allRecordings = allRecordings.where((recording) {
              return recording.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                  (recording.userName?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false) ||
                  recording.hymnId.contains(searchQuery.value);
            }).toList();
          }

          return allRecordings;
        }

        final filteredRecordings = getFilteredRecordings();
        final personalRecordings =
            controller.recordings.where((r) => !r.isPublic).toList();
        // Load community public recordings from Firestore
        final publicRecordings = controller.publicRecordings.toList();

        // Debug: Print current state
        if (kDebugMode) {
          print(
              'RecordingManager: Total recordings: ${controller.recordings.length}');
          print(
              'RecordingManager: Personal: ${personalRecordings.length}, Public: ${publicRecordings.length}');
        }

if (filteredRecordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  searchQuery.value.isNotEmpty ? Icons.search_off : Icons.mic_off_rounded,
                  size: 80,
                  color: colorController.iconColor.value.withValues(alpha: 0.3),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  searchQuery.value.isNotEmpty ? 'No recordings found' : 'No recordings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  searchQuery.value.isNotEmpty 
                      ? 'Try adjusting your search or filters'
                      : 'Start recording your favorite hymns',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshRecordings();
            await controller.refreshPublicRecordings();
          },
          color: colorController.primaryColor.value,
          child: Column(
            children: [
              // Search and Filter Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorController.backgroundColor.value,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorController.primaryColor.value.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Field
                    TextField(
                      controller: searchController,
                      style: TextStyle(color: colorController.textColor.value),
                      decoration: InputDecoration(
                        hintText: 'Search recordings...',
                        hintStyle: TextStyle(
                          color: colorController.textColor.value.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorController.iconColor.value.withValues(alpha: 0.7),
                        ),
                        suffixIcon: searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colorController.iconColor.value.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  searchQuery.value = '';
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorController.primaryColor.value.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorController.primaryColor.value.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorController.primaryColor.value,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => searchQuery.value = value,
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'All',
                            'all',
                            filterOption,
                            colorController,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Personal',
                            'personal',
                            filterOption,
                            colorController,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Public',
                            'public',
                            filterOption,
                            colorController,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Uploaded',
                            'uploaded',
                            filterOption,
                            colorController,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Not Uploaded',
                            'not_uploaded',
                            filterOption,
                            colorController,
                          ),
                        ],
                      ),
                    ),
                    
                    // Results count
                    if (searchQuery.value.isNotEmpty || filterOption.value != 'all')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${filteredRecordings.length} recording${filteredRecordings.length == 1 ? '' : 's'} found',
                          style: TextStyle(
                            color: colorController.textColor.value.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Recordings List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
// Filtered Recordings List
              ...filteredRecordings.asMap().entries.map((entry) {
                final index = entry.key;
                final recording = entry.value;
                final isPublic = recording.isPublic;
                
                return RecordingTileWidget(
                  recording: recording,
                  controller: controller,
                  colorController: colorController,
                  index: index,
                  isPublic: isPublic,
                );
              }),
],
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: ContextAwareFAB(
        onStartRecording: () {
          // Navigate to standalone recording screen
          Get.to(() => const StandaloneRecordingScreen());
        },
      ),
    );
  }

  void _showDriveDialog(BuildContext context, RecordingController controller,
      ColorController colorController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.cloud_done,
              color: colorController.primaryColor.value,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Google Drive',
              style: TextStyle(
                color: colorController.textColor.value,
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
                color: colorController.textColor.value.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.userEmail.value ?? 'Unknown',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final quota = controller.storageQuota.value;
              if (quota == null || quota.usage == null || quota.limit == null) {
                return const SizedBox.shrink();
              }

              final usage = int.tryParse(quota.usage!) ?? 0;
              final limit = int.tryParse(quota.limit!) ?? 1;
              final usageGB = (usage / (1024 * 1024 * 1024)).toStringAsFixed(2);
              final limitGB = (limit / (1024 * 1024 * 1024)).toStringAsFixed(2);
              final percent = (usage / limit).clamp(0.0, 1.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Usage',
                    style: TextStyle(
                      color: colorController.textColor.value
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
                          : colorController.primaryColor.value,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$usageGB GB of $limitGB GB used',
                    style: TextStyle(
                      color: colorController.textColor.value,
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
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          Obx(() => controller.isLoading.value
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
                    await controller.syncFromDrive();
                  },
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorController.primaryColor.value,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                )),
          ElevatedButton(
            onPressed: () {
              controller.signOutFromDrive();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
);
  }

  Widget _buildFilterChip(
    String label,
    String value,
    RxString selectedFilter,
    ColorController colorController,
  ) {
    return Obx(() => FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selectedFilter.value == value
              ? Colors.white
              : colorController.textColor.value,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: selectedFilter.value == value,
      onSelected: (isSelected) {
        selectedFilter.value = isSelected ? value : 'all';
      },
      backgroundColor: colorController.backgroundColor.value,
      selectedColor: colorController.primaryColor.value,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: colorController.primaryColor.value.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ));
  }
}
