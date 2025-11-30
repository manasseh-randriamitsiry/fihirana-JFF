import 'package:flutter/material.dart';

import 'package:fihirana/services/core/version_check_service.dart';

class UpdateButtonWidget extends StatelessWidget {
  final Color iconColor;

  const UpdateButtonWidget({
    super.key,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return const IconButton(
      key: ValueKey('update_button'),
      icon: Icon(Icons.system_update, color: Colors.orange),
      onPressed: VersionCheckService.downloadAndInstallLatestVersion,
    );
  }
}
