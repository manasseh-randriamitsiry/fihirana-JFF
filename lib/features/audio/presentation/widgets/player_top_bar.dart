import 'package:flutter/material.dart';

class PlayerTopBar extends StatelessWidget {
  final VoidCallback? onClose;

  const PlayerTopBar({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 30),
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
          Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}