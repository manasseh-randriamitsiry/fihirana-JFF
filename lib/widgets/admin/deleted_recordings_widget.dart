import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/color_controller.dart';
import '../../controller/recording_controller.dart';
import '../../models/user_recording.dart';

class DeletedRecordingsWidget extends StatefulWidget {
  final Color textColor;
  final Color primaryColor;
  final Color backgroundColor;

  const DeletedRecordingsWidget({
    super.key,
    required this.textColor,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  State<DeletedRecordingsWidget> createState() => _DeletedRecordingsWidgetState();
}

class _DeletedRecordingsWidgetState extends State<DeletedRecordingsWidget> {
  final RecordingController _recordingController = Get.find<RecordingController>();
  final ColorController _colorController = Get.find<ColorController>();
  List<UserRecording> deletedRecordings = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDeletedRecordings();
  }

  Future<void> _loadDeletedRecordings() async {
    setState(() => isLoading = true);
    try {
      final recordings = await _recordingController.getDeletedRecordings();
      setState(() {
        deletedRecordings = recordings;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to load deleted recordings: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  List<UserRecording> getFilteredRecordings() {
    if (searchQuery.isEmpty) return deletedRecordings;
    
    return deletedRecordings.where((recording) {
      return recording.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (recording.userName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          recording.hymnId.contains(searchQuery);
    }).toList();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecordings = getFilteredRecordings();

    return Column(
      children: [
        // Search and Actions Section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _colorController.primaryColor.value.withValues(alpha: 0.1),
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
            children: [
              // Search Field
              TextField(
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  hintText: 'Search deleted recordings...',
                  hintStyle: TextStyle(
                    color: widget.textColor.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _colorController.iconColor.value.withValues(alpha: 0.7),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: _colorController.iconColor.value.withValues(alpha: 0.7),
                          ),
                          onPressed: () {
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _colorController.primaryColor.value.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _colorController.primaryColor.value.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _colorController.primaryColor.value,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              
              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filteredRecordings.length} deleted recording${filteredRecordings.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: widget.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (deletedRecordings.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showClearAllDialog(),
                      icon: const Icon(Icons.delete_sweep, size: 16),
                      label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Recordings List
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : filteredRecordings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 80,
                            color: _colorController.iconColor.value.withValues(alpha: 0.3),
                          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty ? 'No deleted recordings found' : 'No deleted recordings',
                            style: TextStyle(
                              fontSize: 18,
                              color: widget.textColor.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isNotEmpty 
                                ? 'Try adjusting your search'
                                : 'Deleted recordings will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.textColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredRecordings.length,
                      itemBuilder: (context, index) {
                        final recording = filteredRecordings[index];
                        return _buildDeletedRecordingTile(recording, index);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDeletedRecordingTile(UserRecording recording, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.8),
                Colors.red.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          recording.title,
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 10,
              color: widget.textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(recording.durationSeconds),
              style: TextStyle(
                color: widget.textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: widget.textColor.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deleted ${DateFormat.yMMMd().format(recording.createdAt)}',
                style: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Restore Button
            IconButton(
              icon: Icon(
                Icons.restore,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () => _showRestoreDialog(recording),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Restore Recording',
            ),
            const SizedBox(width: 8),
            // Permanently Delete Button
            IconButton(
              icon: Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _showPermanentDeleteDialog(recording),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Permanently Delete',
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          duration: 300.ms,
          begin: index % 2 == 0 ? -0.1 : 0.1,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 300.ms);
  }

  void _showRestoreDialog(UserRecording recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.restore,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Restore Recording',
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to restore "${recording.title}"?',
          style: TextStyle(color: widget.textColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recordingController.restoreRecording(recording);
              _loadDeletedRecordings(); // Refresh list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteDialog(UserRecording recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Permanently Delete',
              style: TextStyle(
                color: widget.textColor,
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
              'Are you sure you want to permanently delete "${recording.title}"?',
              style: TextStyle(color: widget.textColor, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                'This action cannot be undone. The recording will be permanently removed from Google Drive if it exists there.',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recordingController.permanentlyDeleteRecording(recording);
              _loadDeletedRecordings(); // Refresh list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_sweep,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Clear All Deleted Recordings',
              style: TextStyle(
                color: widget.textColor,
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
              'Are you sure you want to permanently delete all ${deletedRecordings.length} deleted recordings?',
              style: TextStyle(color: widget.textColor, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                'This action cannot be undone. All recordings will be permanently removed from Google Drive if they exist there.',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Permanently delete all recordings
              for (final recording in deletedRecordings) {
                await _recordingController.permanentlyDeleteRecording(recording);
              }
              
              _loadDeletedRecordings(); // Refresh list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete All Forever'),
          ),
        ],
      ),
    );
  }
}