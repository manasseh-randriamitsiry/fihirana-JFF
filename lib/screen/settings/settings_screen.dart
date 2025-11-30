import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/font_picker_widget.dart';
import '../../widgets/settings/settings_section_header.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/audio_cache_dialog.dart';
import '../../widgets/common/localization_extension.dart';
import '../../widgets/language_picker_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ColorController colorController = Get.find<ColorController>();

  void _showAudioCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => const AudioCacheDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            context.translate((l) => l.settings),
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
                title: context.translate((l) => l.theme),
                animationDelay: 0,
              ),

              SettingsCard(
                icon: Icons.color_lens_outlined,
                label: context.translate((l) => l.changeColor),
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
                icon: Icons.language,
                label: context.translate((l) => l.language),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => const LanguagePickerDialog(),
                ),
                animationDelay: 125,
              ),

              const SizedBox(height: 12),

              SettingsCard(
                icon: Icons.font_download_outlined,
                label: context.translate((l) => l.fontStyle),
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
                title: context.translate((l) => l.bible),
                animationDelay: 200,
              ),

              SettingsCard(
                icon: Icons.auto_stories,
                label: context.translate((l) => l.dailyBibleVerse),
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
                label: context.translate((l) => l.audioCache),
                onTap: () => _showAudioCacheDialog(),
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
