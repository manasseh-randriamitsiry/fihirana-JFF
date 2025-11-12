import 'package:flutter/material.dart';
import 'package:fihirana/services/version_check_service.dart';
import '../l10n/app_localizations.dart';

class UpdateDialog extends StatefulWidget {
  final bool updateAvailable;

  const UpdateDialog({super.key, required this.updateAvailable});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  bool _downloadCompleted = false;

  Future<void> _startFlexibleUpdate() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      await VersionCheckService.triggerFlexibleUpdate();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadCompleted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorDownloadingUpdate2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeFlexibleUpdate() async {
    try {
      await VersionCheckService.completeFlexibleUpdate();
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorInstallingUpdate),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      await VersionCheckService.triggerImmediateUpdate();
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCheckingUpdates),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: Text(l10n.updateAvailableContent),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.no),
        ),
        if (!_downloadCompleted && !_isDownloading) ...[
          TextButton(
            onPressed: _startFlexibleUpdate,
            child: Text(l10n.download),
          ),
          TextButton(
            onPressed: _performImmediateUpdate,
            child: Text(l10n.updateNow),
          ),
        ],
        if (_isDownloading) ...[
          TextButton(
            onPressed: null,
            child: Text(l10n.downloading3),
          ),
        ],
        if (_downloadCompleted) ...[
          TextButton(
            onPressed: _completeFlexibleUpdate,
            child: Text(l10n.install),
          ),
        ],
      ],
    );
  }
}
