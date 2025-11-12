import 'package:flutter/material.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:fihirana/services/apk_download_service.dart';

class UpdateCheckerWidget extends StatefulWidget {
  final Widget child;

  const UpdateCheckerWidget({super.key, required this.child});

  @override
  State<UpdateCheckerWidget> createState() => _UpdateCheckerWidgetState();
}

class _UpdateCheckerWidgetState extends State<UpdateCheckerWidget> {
  bool _updateAvailable = false;
  bool _checkingForUpdates = false;
  bool _flexibleUpdateDownloaded = false;

  @override
  void initState() {
    super.initState();

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });

    VersionCheckService.setOnFlexibleUpdateDownloadedCallback(() {
      if (mounted) {
        setState(() {
          _flexibleUpdateDownloaded = true;
        });
      }
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateAvailable = await VersionCheckService.checkForUpdateManually();
      if (mounted) {
        setState(() {
          _updateAvailable = updateAvailable;
          _checkingForUpdates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _updateAvailable = false;
          _checkingForUpdates = false;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tsy afaka mijery rindrambaiko'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAndUpdate() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      await VersionCheckService.downloadAndInstallLatestVersion();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tsy afaka mandefa: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hampiditra vaovao'),
          content: const Text(
              'Tena te hampiditra ny version vaovao? Handefa anaty rakitra ary hametraka azy ho azy.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tsia'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadAndUpdate();
              },
              child: const Text('Eny'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_updateAvailable)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _showUpdateDialog,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.system_update,
                    size: 32,
                    color: Colors.orange,
                  ),
                  if (!_flexibleUpdateDownloaded)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                      ),
                    ),
                  if (_flexibleUpdateDownloaded)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_checkingForUpdates)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
}