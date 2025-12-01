import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/translation_controller.dart';
import '../../l10n/app_localizations.dart';

class TranslationToggleWidget extends StatelessWidget {
  const TranslationToggleWidget({Key? key}) : super(key: key);

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
                      AppLocalizations.of(context)!.autoTranslate ?? 'Auto-Translate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Switch(
                      value: translationController.autoTranslate,
                      onChanged: (value) {
                        translationController.toggleAutoTranslate();
                        _showSnackBar(
                          context,
                          value ? 'Auto-translate enabled' : 'Auto-translate disabled',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Automatically translate hymn content to your preferred language',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                if (translationController.isTranslating) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  Text(
                    'Translating...',
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