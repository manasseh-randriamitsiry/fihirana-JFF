import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/font_picker_widget.dart';
import '../../widgets/settings/settings_section_header.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/audio_cache_dialog.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ColorController colorController = Get.find<ColorController>();

  void _showAudioCacheDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => const AudioCacheDialog(),
    );
  }



@override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
          icon: Icon(
            Icons.menu_rounded,
            color: colorController.iconColor.value,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Appearance Section
            SettingsSectionHeader(
              title: l10n.theme,
              animationDelay: 0,
            ),

            SettingsCard(
              icon: Icons.color_lens_outlined,
              label: l10n.changeColor,
              onTap: () => Get.dialog(
                Dialog(
                  backgroundColor: colorController.backgroundColor.value,
                  child: ColorPickerWidget(),
                ),
              ),
              animationDelay: 100,
            ),

            const SizedBox(height: 12),

            SettingsCard(
              icon: Icons.font_download_outlined,
              label: l10n.fontStyle,
              onTap: () => Get.dialog(
                Dialog(
                  backgroundColor: colorController.backgroundColor.value,
                  child: FontPickerWidget(),
                ),
              ),
              animationDelay: 150,
            ),

            // Bible Section
            SettingsSectionHeader(
              title: l10n.bible,
              animationDelay: 200,
            ),

            SettingsCard(
              icon: Icons.auto_stories,
              label: l10n.dailyBibleVerse,
              onTap: () => Get.toNamed('/daily_verse_settings'),
              iconColor: Colors.purple,
              animationDelay: 250,
            ),

            // Audio Section
            const SettingsSectionHeader(
              title: 'Audio',
              animationDelay: 300,
            ),

            SettingsCard(
              icon: Icons.storage_rounded,
              label: l10n.audioCache,
              onTap: () => _showAudioCacheDialog(l10n),
              iconColor: Colors.orange,
              animationDelay: 350,
            ),

            const SizedBox(height: 32),
          ],
),
      ),
      ),
    );
  }
}
