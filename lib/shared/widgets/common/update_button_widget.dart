import 'package:flutter/material.dart';

class UpdateButtonWidget extends StatelessWidget {
  final Color iconColor;

  const UpdateButtonWidget({
    super.key,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('update_button'),
      icon: const Icon(Icons.system_update, color: Colors.orange),
      onPressed: () {},
    );
  }
}
