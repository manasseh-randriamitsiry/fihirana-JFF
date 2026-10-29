import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class AgreementCheckboxWidget extends StatelessWidget {
  final bool isAccepted;
  final String text;
  final VoidCallback onTap;

  const AgreementCheckboxWidget({
    super.key,
    required this.isAccepted,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppScale.radiusRow),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppScale.space12),
        decoration: BoxDecoration(
          color: isAccepted ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppScale.radiusRow),
          border: Border.all(
            color: isAccepted ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isAccepted ? Colors.green : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAccepted ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: isAccepted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: AppScale.space12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
