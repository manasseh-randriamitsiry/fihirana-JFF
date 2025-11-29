import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';

class RecordingSaveDialogWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final recordingController = Get.find<RecordingController>();
    
    bool uploadToDrive = false;
    bool isPublic = false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setState) => Container(
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
                  // Success icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 32,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Recording Complete!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name input
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Recording Name',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      prefixIcon: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Privacy toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        isPublic ? 'Public Recording' : 'Private Recording',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isPublic
                            ? 'Anyone can listen to this recording'
                            : 'Only you can listen to this recording',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      value: isPublic,
                      onChanged: (value) {
                        setState(() => isPublic = value);
                      },
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upload to Drive checkbox
                  Obx(() => Container(
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
                          value: uploadToDrive,
                          onChanged: (value) {
                            setState(() => uploadToDrive = value ?? false);
                          },
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.2)),
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      // Primary save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Save recording first
                            onSave();
                            
                            // Handle upload and public sharing if needed
                            if (uploadToDrive || isPublic) {
                              final lastRecording = recordingController.recordings.last;
                              if (uploadToDrive) {
                                await recordingController.uploadToDrive(lastRecording);
                              }
                              if (isPublic) {
                                await recordingController.publishRecording(lastRecording);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            foregroundColor: colorController.primaryColor.value,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text('Save & Close', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Secondary options
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onDiscard,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Discard',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Save but don't close - allow new recording
                                onSave();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Save & New',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}