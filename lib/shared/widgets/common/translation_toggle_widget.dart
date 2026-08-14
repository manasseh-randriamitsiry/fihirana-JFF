import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/localization/translation_controller.dart';

class TranslationToggleWidget extends StatelessWidget {
  const TranslationToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationController>(
      builder: (context, translationController, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).autoTranslate,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Switch(
                      value: translationController.autoTranslate,
                      onChanged: (value) {
                        translationController.toggleAutoTranslate();
                        _showSnackBar(
                          context,
                          value
                              ? AppLocalizations.of(context).translationEnabled
                              : AppLocalizations.of(context)
                                  .translationDisabled,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).automaticTranslationDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                ),
                if (translationController.isTranslating) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).translating,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
