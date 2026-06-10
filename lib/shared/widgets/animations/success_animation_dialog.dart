import 'package:flutter/material.dart';
import 'success_check_animation.dart';

class SuccessAnimationDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const SuccessAnimationDialog({
    super.key,
    required this.message,
    this.onDismiss,
  });

  static void show(BuildContext context, {required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessAnimationDialog(
        message: message,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (context.mounted) {
        onDismiss?.call();
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 100,
              width: 100,
              child: SuccessCheckAnimation(
                size: 100,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
