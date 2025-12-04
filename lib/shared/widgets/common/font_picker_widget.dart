import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class FontPickerWidget extends StatelessWidget {
  final FontController _fontController = Get.find<FontController>();
  final ColorController _colorController = Get.find<ColorController>();

  FontPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _colorController.primaryColor.value,
                  _colorController.primaryColor.value.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.font_download,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.chooseFontStyle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Font List
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                key: const PageStorageKey('fonts_list'),
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: _fontController.availableFonts.length,
                itemBuilder: (context, index) {
                  final fontName = _fontController.availableFonts[index];
                  return Obx(() {
                    final isSelected =
                        _fontController.currentFont.value == fontName;
                    return Container(
                      key: ValueKey(fontName),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _colorController.primaryColor.value
                                .withValues(alpha: 0.1)
                            : _colorController.backgroundColor.value,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _colorController.primaryColor.value
                              : _colorController.textColor.value
                                  .withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: _colorController.primaryColor.value
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _fontController.changeFont(fontName);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Radio indicator
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _colorController.primaryColor.value
                                          : _colorController.textColor.value
                                              .withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? _colorController.primaryColor.value
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Font info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fontName,
                                        style: TextStyle(
                                          color:
                                              _colorController.textColor.value,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.sampleText,
                                        style: _fontController.getFontStyle(
                                          fontName,
                                          TextStyle(
                                            color: _colorController
                                                .textColor.value
                                                .withValues(alpha: 0.8),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),

          // Footer with action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _fontController.importFont(),
                      icon: Icon(
                        Icons.add,
                        color: _colorController.primaryColor.value,
                        size: 20,
                      ),
                      label: Text(
                        '+',
                        style: TextStyle(
                          color: _colorController.primaryColor.value,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final Uri url = Uri.parse('https://fonts.google.com');
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(l10n.couldNotLaunchGoogleFonts)),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        l10n.getFonts,
                        style: TextStyle(
                          color: _colorController.textColor.value
                              .withValues(alpha: 0.7),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        l10n.accept,
                        style: TextStyle(
                          color: _colorController.primaryColor.value,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
