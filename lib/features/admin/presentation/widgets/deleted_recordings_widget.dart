import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/shared/widgets/common/loading_widget.dart';
import 'package:fihirana/features/recording/presentation/widgets/recording_tile_widget.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class DeletedRecordingsWidget extends StatefulWidget {
  const DeletedRecordingsWidget({super.key});

  @override
  State<DeletedRecordingsWidget> createState() =>
      _DeletedRecordingsWidgetState();
}

class _DeletedRecordingsWidgetState extends State<DeletedRecordingsWidget> {
  final RecordingController _controller = Get.find<RecordingController>();
  List<UserRecording> deletedRecordings = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDeletedRecordings();
  }

  Future<void> _loadDeletedRecordings() async {
    try {
      setState(() => isLoading = true);
      final recordings = await _controller.getDeletedRecordings();
      setState(() {
        deletedRecordings = recordings;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        Get.snackbar(
          AppLocalizations.of(context).error,
          AppLocalizations.of(context)
              .failedToLoadDeletedRecordings(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          colorText: Theme.of(context).colorScheme.onErrorContainer,
        );
      }
    }
  }

  List<UserRecording> get filteredRecordings {
    if (searchQuery.isEmpty) return deletedRecordings;
    return deletedRecordings
        .where((recording) =>
            recording.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            recording.hymnId.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).searchDeletedRecordings,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),

        // Refresh button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadDeletedRecordings,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).refresh),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)
                    .deletedRecordingsCount(filteredRecordings.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recordings list
        Expanded(
          child: isLoading
              ? const LoadingWidget()
              : filteredRecordings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      key: const PageStorageKey('deleted_recordings_list'),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecordings.length,
                      itemBuilder: (context, index) {
                        final recording = filteredRecordings[index];
                        return Padding(
                          key: ValueKey(recording.id),
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: RecordingTileWidget(
                            recording: recording,
                            index: 0,
                            isDeleted: true,
                            onRestore: () => _restoreRecording(recording),
                            onPermanentDelete: () =>
                                _permanentDelete(recording),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.delete_outline_rounded,
      title: searchQuery.isNotEmpty
          ? AppLocalizations.of(context).noDeletedRecordingsFound
          : AppLocalizations.of(context).noDeletedRecordings,
      message: searchQuery.isNotEmpty
          ? AppLocalizations.of(context).tryAdjustingSearchTerms
          : AppLocalizations.of(context).deletedRecordingsWillAppearHere,
      action: searchQuery.isNotEmpty
          ? FilledButton.tonal(
              onPressed: () => setState(() => searchQuery = ''),
              child: Text(AppLocalizations.of(context).clearSearch),
            )
          : null,
    );
  }

  Future<void> _restoreRecording(UserRecording recording) async {
    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context).restoreRecording),
        content:
            Text(AppLocalizations.of(context).sureToDelete(recording.title)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppLocalizations.of(context).restoreRecording),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.restoreRecording(recording);
      _loadDeletedRecordings(); // Refresh the list
    }
  }

  Future<void> _permanentDelete(UserRecording recording) async {
    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context).permanentDelete),
        content: Text(
          '${AppLocalizations.of(context).sureToDelete(recording.title)} ${AppLocalizations.of(context).historyCannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppLocalizations.of(context).deletePermanently),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.permanentlyDeleteRecording(recording);
      _loadDeletedRecordings(); // Refresh the list
    }
  }
}
