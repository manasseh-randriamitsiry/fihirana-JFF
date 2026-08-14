import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/features/bible/presentation/pages/bible_share_composer_screen.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleSelectionActionBarWidget extends StatelessWidget {
  const BibleSelectionActionBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bibleController = Get.find<BibleController>();
    final authController = Get.find<AuthController>();
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final hasSelection = bibleController.selectedVerses.isNotEmpty;
      if (!bibleController.isSelecting || !hasSelection) {
        return const SizedBox.shrink();
      }

      final isLoggedIn = authController.isAuthenticated;

      final selectedReference = bibleController.getSelectedVersesText();
      final shareData = bibleController.buildSelectedShareData();

      return Positioned(
        bottom: 24,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // Clear Selection
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  bibleController.clearSelection();
                },
                icon: Icon(Icons.close, color: colors.onSurface),
                tooltip: l10n.clear,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedReference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isLoggedIn)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    bibleController.saveHighlight();
                  },
                  icon: Icon(Icons.highlight_rounded, color: colors.secondary),
                  tooltip: l10n.saveChanges,
                ),
              IconButton(
                onPressed: shareData == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                BibleShareComposerScreen(data: shareData),
                          ),
                        );
                      },
                icon: Icon(
                  Icons.share_rounded,
                  color: colors.primary,
                ),
                tooltip: l10n.share,
              ),
            ],
          ),
        ),
      );
    });
  }
}
