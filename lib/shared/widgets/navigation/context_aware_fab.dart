import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Action model for FAB actions
class FABAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;

  FABAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
  });
}

/// Context-aware FAB that shows different actions based on current route
class ContextAwareFAB extends StatefulWidget {
  /// Optional custom actions to override route-based actions
  final List<FABAction>? customActions;

  /// Callback functions for contact screen actions
  final VoidCallback? onImportContact;
  final VoidCallback? onAddContact;

  /// Callback functions for recording/player actions (for future use)
  final VoidCallback? onStartRecording;
  final VoidCallback? onViewPlayerStats;
  final VoidCallback? onViewRecordingStats;
  final VoidCallback? onAddAnnouncement;
  final VoidCallback? onRefreshAnnouncements;

  const ContextAwareFAB({
    super.key,
    this.customActions,
    this.onImportContact,
    this.onAddContact,
    this.onStartRecording,
    this.onViewPlayerStats,
    this.onViewRecordingStats,
    this.onAddAnnouncement,
    this.onRefreshAnnouncements,
  });

  @override
  State<ContextAwareFAB> createState() => _ContextAwareFABState();
}

class _ContextAwareFABState extends State<ContextAwareFAB> {
  final ColorController colorController = Get.find<ColorController>();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Get actions for current route
    final actions = widget.customActions ?? _getActionsForRoute(context);

    // If no actions, return empty container
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine if we're on the right side (for contact screen)
    final currentActions = _getActionsForRoute(context);
    final isOnRight = currentActions == _getContactActions();

    return Stack(
      alignment: isOnRight ? Alignment.bottomRight : Alignment.bottomLeft,
      children: [
        // Speed dial action buttons and main FAB
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isOnRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Action buttons (shown when expanded)
            if (_isExpanded) ...[
              ...actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                final delay = (index + 1) * 50;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: isOnRight
                      ? [
                          // FAB comes first when on right
                          FloatingActionButton(
                            heroTag: "fab_${action.label}",
                            mini: true,
                            onPressed: () {
                              setState(() {
                                _isExpanded = false;
                              });
                              action.onTap();
                            },
                            backgroundColor: action.backgroundColor ??
                                colorController.primaryColor.value
                                    .withValues(alpha: 0.9),
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: Icon(
                              action.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 12, bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorController.backgroundColor.value,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              action.label,
                              style: TextStyle(
                                color: colorController.textColor.value,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]
                      : [
                          // Original order when on left
                          Container(
                            margin:
                                const EdgeInsets.only(right: 12, bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorController.backgroundColor.value,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              action.label,
                              style: TextStyle(
                                color: colorController.textColor.value,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          FloatingActionButton(
                            heroTag: "fab_${action.label}",
                            mini: true,
                            onPressed: () {
                              setState(() {
                                _isExpanded = false;
                              });
                              action.onTap();
                            },
                            backgroundColor: action.backgroundColor ??
                                colorController.primaryColor.value
                                    .withValues(alpha: 0.9),
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: Icon(
                              action.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                ).animate().fadeIn(duration: 200.ms, delay: delay.ms).slideX(
                    begin: isOnRight ? 0.2 : -0.2,
                    end: 0,
                    duration: 200.ms,
                    delay: delay.ms);
              }),
              const SizedBox(height: 4),
            ],

// Main FAB
            FloatingActionButton(
              heroTag: "mainContextFAB",
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              backgroundColor: _isRecordingScreen()
                  ? Colors.red
                  : colorController.primaryColor.value,
              shape: const CircleBorder(),
              elevation: 6,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _isExpanded ? 0.125 : 0, // 45 degrees when expanded
                child: _isRecordingScreen()
                    ? Icon(
                        _isExpanded ? Icons.close : Icons.mic,
                        color: Colors.white,
                      )
                    : Icon(
                        _isExpanded ? Icons.close : Icons.add,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Check if current screen is a recording screen
  bool _isRecordingScreen() {
    return widget.onViewRecordingStats != null ||
        widget.onStartRecording != null;
  }

  /// Get actions based on current route
  List<FABAction> _getActionsForRoute(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;

    switch (route) {
      case '/contacts':
        return _getContactActions();

      // Add more routes as needed
      // case '/player' or '/hymns':
      //   return _getPlayerActions();
      // case '/recording':
      //   return _getRecordingActions();

      default:
        // If no route name, check if we have callbacks for contact actions
        // This handles cases where routes aren't named
        if (widget.onImportContact != null || widget.onAddContact != null) {
          return _getContactActions();
        }
        if (widget.onStartRecording != null) {
          return _getRecordingActions();
        }
        if (widget.onViewPlayerStats != null) {
          return _getPlayerActions();
        }
        if (widget.onViewRecordingStats != null) {
          return _getRecordingActions();
        }
        if (widget.onAddAnnouncement != null ||
            widget.onRefreshAnnouncements != null) {
          return _getAnnouncementActions();
        }
        return [];
    }
  }

  /// Contact screen actions
  List<FABAction> _getContactActions() {
    final l10n = AppLocalizations.of(context);
    final actions = <FABAction>[];

    if (widget.onImportContact != null) {
      actions.add(FABAction(
        label: l10n.importContact,
        icon: Icons.contacts,
        onTap: widget.onImportContact!,
        backgroundColor:
            colorController.primaryColor.value.withValues(alpha: 0.8),
      ));
    }

    if (widget.onAddContact != null) {
      actions.add(FABAction(
        label: l10n.addContact,
        icon: Icons.add,
        onTap: widget.onAddContact!,
      ));
    }

    return actions;
  }

  /// Player/Hymn screen actions (for future use)
  List<FABAction> _getPlayerActions() {
    final l10n = AppLocalizations.of(context);
    final actions = <FABAction>[];

    if (widget.onStartRecording != null) {
      actions.add(FABAction(
        label: l10n.record,
        icon: Icons.mic,
        onTap: widget.onStartRecording!,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
      ));
    }

    if (widget.onViewPlayerStats != null) {
      actions.add(FABAction(
        label: l10n.playerStats,
        icon: Icons.analytics,
        onTap: widget.onViewPlayerStats!,
      ));
    }

    return actions;
  }

  /// Recording screen actions (for future use)
  List<FABAction> _getRecordingActions() {
    final l10n = AppLocalizations.of(context);
    final actions = <FABAction>[];

    if (widget.onStartRecording != null) {
      actions.add(FABAction(
        label: l10n.startRecording,
        icon: Icons.mic,
        onTap: widget.onStartRecording!,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
      ));
    }

    if (widget.onViewRecordingStats != null) {
      actions.add(FABAction(
        label: l10n.recordingStats,
        icon: Icons.analytics,
        onTap: widget.onViewRecordingStats!,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
      ));
    }

    return actions;
  }

  /// Announcement screen actions
  List<FABAction> _getAnnouncementActions() {
    final l10n = AppLocalizations.of(context);
    final actions = <FABAction>[];

    if (widget.onAddAnnouncement != null) {
      actions.add(FABAction(
        label: l10n.addAnnouncement,
        icon: Icons.add,
        onTap: widget.onAddAnnouncement!,
      ));
    }

    if (widget.onRefreshAnnouncements != null) {
      actions.add(FABAction(
        label: l10n.refresh,
        icon: Icons.refresh,
        onTap: widget.onRefreshAnnouncements!,
        backgroundColor:
            colorController.primaryColor.value.withValues(alpha: 0.8),
      ));
    }

    return actions;
  }
}
