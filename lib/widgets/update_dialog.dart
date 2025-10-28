import 'package:flutter/material.dart';
import 'package:fihirana/services/version_check_service.dart';

class UpdateDialog extends StatefulWidget {
  final bool updateAvailable;

  const UpdateDialog({super.key, required this.updateAvailable});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  final double _downloadProgress = 0.0;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tsy afaka mandefa ny fakàna'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tsy afaka mametraka ny vaovao'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tsy afaka mandefa ny fanavaozana'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vaovao misy'),
      content: const Text('Misy rindrambaiko vaovao azo ampiasaina. Tianao haka izany ve?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Tsia'),
        ),
        if (!_downloadCompleted && !_isDownloading) ...[
          TextButton(
            onPressed: _startFlexibleUpdate,
            child: const Text('Fakàna'),
          ),
          TextButton(
            onPressed: _performImmediateUpdate,
            child: const Text('Vaovao haingana'),
          ),
        ],
        if (_isDownloading) ...[
          const TextButton(
            onPressed: null,
            child: Text('Mandefa fakàna...'),
          ),
        ],
        if (_downloadCompleted) ...[
          TextButton(
            onPressed: _completeFlexibleUpdate,
            child: const Text('Apetraho'),
          ),
        ],
      ],
    );
  }
}