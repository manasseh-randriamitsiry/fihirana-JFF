import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class BibleSettingsBottomSheetWidget extends StatefulWidget {
  final double fontSize;
  final String fontFamily;
  final Function(double, String) onSettingsChanged;

  const BibleSettingsBottomSheetWidget({
    super.key,
    required this.fontSize,
    required this.fontFamily,
    required this.onSettingsChanged,
  });

  @override
  State<BibleSettingsBottomSheetWidget> createState() =>
      _BibleSettingsBottomSheetWidgetState();
}

class _BibleSettingsBottomSheetWidgetState
    extends State<BibleSettingsBottomSheetWidget> {
  late double _currentFontSize;
  late String _currentFontFamily;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.fontSize;
    _currentFontFamily = widget.fontFamily;
  }

  @override
  Widget build(BuildContext context) {
    final fontController = Get.find<FontController>();
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppScale.radiusFloat)),
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .7)),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppScale.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppScale.radiusMark),
              ),
            ),
          ),
          const SizedBox(height: AppScale.space24),
          Text(
            'Apparence',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppScale.space24),
          AppGroupedSurface(
            padding: const EdgeInsets.fromLTRB(AppScale.space16,
                AppScale.space12, AppScale.space16, AppScale.space16),
            children: [
              Row(
                children: [
                  Icon(Icons.text_fields, size: 20, color: colors.primary),
                  const SizedBox(width: AppScale.space12),
                  Expanded(
                    child: Slider(
                      value: _currentFontSize,
                      min: 12,
                      max: 32,
                      activeColor: colors.primary,
                      onChanged: (value) {
                        setState(() => _currentFontSize = value);
                        widget.onSettingsChanged(value, _currentFontFamily);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: AppScale.space4),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppScale.radiusControl),
                    ),
                    child: Text(
                      '${_currentFontSize.toInt()}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Police (${fontController.availableFonts.length} polices)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: AppScale.space12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fontController.availableFonts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppScale.space8),
                  itemBuilder: (context, index) {
                    final fontName = fontController.availableFonts[index];
                    return _buildHorizontalFontOption(fontName, fontName);
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(
                      ThemeMode.light, Icons.light_mode_rounded, 'Clair'),
                  _buildThemeOption(
                      ThemeMode.dark, Icons.dark_mode_rounded, 'Sombre'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppScale.space16),
        ],
      ),
    );
  }

  Widget _buildHorizontalFontOption(String family, String fontName) {
    final isSelected = _currentFontFamily == family;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() => _currentFontFamily = family);
        widget.onSettingsChanged(_currentFontSize, family);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.gutter, vertical: AppScale.space12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.primaryContainer,
          borderRadius: BorderRadius.circular(AppScale.radiusFloat),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          fontName,
          style: Get.find<FontController>().getFontStyle(
            fontName,
            TextStyle(
              color: isSelected ? colors.onPrimary : colors.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, IconData icon, String label) {
    final colorController = Get.find<ColorController>();
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final isSelected = colorController.themeMode == mode;
      return GestureDetector(
        onTap: () {
          // Index 0 is Default (Light), Index 5 is Dark Mode
          final index = mode == ThemeMode.light ? 0 : 5;
          colorController.setColorScheme(index);
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppScale.space12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.onPrimary : colors.onSurface,
              ),
            ),
            const SizedBox(height: AppScale.space8),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }
}
