import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';

class RecordingSaveDialog extends StatefulWidget {
  final RecordingController controller;
  final ColorController colorController;
  final UserRecording? currentRecording;
  final TextEditingController nameController;
  final Function(bool uploadToDrive, bool isPublic) onSave;
  final VoidCallback onDiscard;

  const RecordingSaveDialog({
    super.key,
    required this.controller,
    required this.colorController,
    required this.currentRecording,
    required this.nameController,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<RecordingSaveDialog> createState() => _RecordingSaveDialogState();
}

class _RecordingSaveDialogState extends State<RecordingSaveDialog> {
  bool _uploadToDrive = false;
  bool _isPublic = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Material(
            color: Colors.transparent,
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
                    widget.colorController.primaryColor.value,
                    widget.colorController.primaryColor.value.withValues(alpha: 0.8),
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
                      )
                          .animate()
                          .scale(duration: 400.ms, curve: Curves.elasticOut),

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
                        controller: widget.nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Recording Name',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.white, width: 2),
                          ),
                          prefixIcon: Icon(Icons.edit,
                              color: Colors.white.withValues(alpha: 0.8)),
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
                            _isPublic ? 'Public Recording' : 'Private Recording',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _isPublic
                                ? 'Anyone can listen to this recording'
                                : 'Only you can listen to this recording',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          value: _isPublic,
                          onChanged: (value) {
                            setDialogState(() => _isPublic = value);
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
                              subtitle: widget.controller.isDriveSignedIn.value
                                  ? Text(
                                      'Signed in as ${widget.controller.userEmail.value}',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                    )
                                  : Text(
                                      'You will be prompted to sign in',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                              value: _uploadToDrive,
                              onChanged: (value) {
                                setDialogState(
                                    () => _uploadToDrive = value ?? false);
                              },
                              checkColor: Colors.white,
                              fillColor: WidgetStateProperty.all(
                                  Colors.white.withValues(alpha: 0.2)),
                            ),
                          )),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onDiscard,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'Discard',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Pass the state to the callback
                                widget.onSave(_uploadToDrive, _isPublic);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    widget.colorController.primaryColor.value,
                              ),
                              child: Text(l10n.save),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}