import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';

class SaveDialogDriveUpload extends StatefulWidget {
  final bool initialValue;
  final Function(bool) onChanged;

  const SaveDialogDriveUpload({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<SaveDialogDriveUpload> createState() => _SaveDialogDriveUploadState();
}

class _SaveDialogDriveUploadState extends State<SaveDialogDriveUpload> {
  late bool _uploadToDrive;
  final RecordingController recordingController = Get.find<RecordingController>();

  @override
  void initState() {
    super.initState();
    _uploadToDrive = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CheckboxListTile(
            title: const Text(
              'Upload to Google Drive',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: recordingController.isDriveSignedIn.value
                ? Text(
                    'Signed in as ${recordingController.userEmail.value}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  )
                : Text(
                    'You will be prompted to sign in',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
            value: _uploadToDrive,
            onChanged: (value) {
              setState(() => _uploadToDrive = value ?? false);
              widget.onChanged(_uploadToDrive);
            },
            checkColor: Colors.white,
            fillColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.2)),
          ),
        ));
  }
}