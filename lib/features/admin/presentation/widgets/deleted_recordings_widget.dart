import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/shared/widgets/common/loading_widget.dart';
import 'package:fihirana/features/recording/presentation/widgets/recording_tile_widget.dart';

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
      Get.snackbar(
        'Error',
        'Failed to load deleted recordings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchDeletedRecordings,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadDeletedRecordings,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.refresh),
              ),
              const SizedBox(width: 8),
              Text(
                '${filteredRecordings.length} deleted recordings',
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
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecordings.length,
                      itemBuilder: (context, index) {
                        final recording = filteredRecordings[index];
                        return Padding(
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No deleted recordings found'
                : 'No deleted recordings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Deleted recordings will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => searchQuery = ''),
              child: Text(AppLocalizations.of(context)!.clearSearch),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _restoreRecording(UserRecording recording) async {
    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreRecording),
        content: Text(AppLocalizations.of(context)!.sureToDelete(recording.title)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppLocalizations.of(context)!.restoreRecording),
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
        title: Text(AppLocalizations.of(context)!.permanentDelete),
        content: Text(
          '${AppLocalizations.of(context)!.sureToDelete(recording.title)} ${AppLocalizations.of(context)!.historyCannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppLocalizations.of(context)!.deletePermanently),
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
