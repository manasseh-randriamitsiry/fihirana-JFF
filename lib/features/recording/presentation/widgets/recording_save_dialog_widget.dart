import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'save_dialog_header.dart';
import 'save_dialog_name_input.dart';
import 'save_dialog_privacy_toggle.dart';
import 'save_dialog_drive_upload.dart';
import 'save_dialog_actions.dart';

class RecordingSaveDialogWidget extends StatefulWidget {
  final TextEditingController nameController;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const RecordingSaveDialogWidget({
    super.key,
    required this.nameController,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<RecordingSaveDialogWidget> createState() => _RecordingSaveDialogWidgetState();
}

class _RecordingSaveDialogWidgetState extends State<RecordingSaveDialogWidget> {
  bool uploadToDrive = false;
  bool isPublic = false;

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
          vertical: MediaQuery.of(context).size.height * 0.1,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorController.primaryColor.value,
              colorController.primaryColor.value.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const SaveDialogHeader(),

                // Name input
                SaveDialogNameInput(nameController: widget.nameController),

                const SizedBox(height: 20),

                // Privacy toggle
                SaveDialogPrivacyToggle(
                  initialValue: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                ),

                const SizedBox(height: 16),

                // Upload to Drive checkbox
                SaveDialogDriveUpload(
                  initialValue: uploadToDrive,
                  onChanged: (value) => setState(() => uploadToDrive = value),
                ),

                const SizedBox(height: 24),

                // Action buttons
                SaveDialogActions(
                  onSave: widget.onSave,
                  onDiscard: widget.onDiscard,
                  uploadToDrive: uploadToDrive,
                  isPublic: isPublic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}