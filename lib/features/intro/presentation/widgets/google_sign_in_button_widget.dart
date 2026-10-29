import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class GoogleSignInButtonWidget extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback onPressed;

  const GoogleSignInButtonWidget({
    super.key,
    required this.isLoading,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: AppScale.gutter,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Image.asset(
                'assets/images/google_logo.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.login, size: 24),
              ),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(
              horizontal: AppScale.space24, vertical: AppScale.space12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppScale.radiusSurface),
          ),
          elevation: 8,
        ),
      ),
    );
  }
}
