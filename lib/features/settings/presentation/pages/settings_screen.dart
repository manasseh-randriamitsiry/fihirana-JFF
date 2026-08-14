import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/app/theme/theme_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/settings/presentation/widgets/audio_cache_dialog.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/shared/widgets/common/color_picker_widget.dart';
import 'package:fihirana/shared/widgets/common/font_picker_widget.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/simple_language_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return AppPageScaffold(
      title: context.translate((l) => l.settings),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: Get.find<ShellController>().toggleDrawer,
        icon: const Icon(Icons.menu_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppSection(
            title: context.translate((l) => l.theme),
            child: AppGroupedSurface(
              children: [
                AppListRow(
                  icon: Icons.palette_outlined,
                  title: context.translate((l) => l.changeColor),
                  onTap: () => ColorPickerWidget.showColorPickerDialog(context),
                ),
                const AppGroupDivider(),
                AppListRow(
                  icon: Icons.language_rounded,
                  title: context.translate((l) => l.language),
                  onTap: () => SimpleLanguagePicker.showLanguagePicker(context),
                ),
                const AppGroupDivider(),
                AppListRow(
                  icon: Icons.text_fields_rounded,
                  title: context.translate((l) => l.fontStyle),
                  onTap: () => FontPickerWidget.showFontPicker(context),
                ),
                const AppGroupDivider(),
                Obx(
                  () => AppListRow(
                    icon: Icons.dark_mode_outlined,
                    title: context.translate((l) => l.darkMode),
                    trailing: Switch(
                      value: themeController.isDarkMode.value,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                    onTap: themeController.toggleTheme,
                  ),
                ),
              ],
            ),
          ),
          AppSection(
            title: context.translate((l) => l.bible),
            child: AppGroupedSurface(
              children: [
                AppListRow(
                  icon: Icons.auto_stories_outlined,
                  title: context.translate((l) => l.dailyBibleVerse),
                  onTap: () => Get.toNamed('/daily_verse_settings'),
                ),
              ],
            ),
          ),
          AppSection(
            title: context.translate((l) => l.audioSection),
            child: AppGroupedSurface(
              children: [
                AppListRow(
                  icon: Icons.storage_outlined,
                  title: context.translate((l) => l.audioCache),
                  onTap: () => AudioCacheDialog.showAudioCacheDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
