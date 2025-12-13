import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/shared/widgets/common/color_picker_widget.dart';
import 'package:fihirana/shared/widgets/common/font_picker_widget.dart';
import 'package:fihirana/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:fihirana/features/settings/presentation/widgets/settings_card.dart';
import 'package:fihirana/features/settings/presentation/widgets/audio_cache_dialog.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/simple_language_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ColorController colorController = Get.find<ColorController>();

  void _showAudioCacheDialog() {
    AudioCacheDialog.showAudioCacheDialog(context);
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
                 onTap: () => ColorPickerWidget.showColorPickerDialog(context),
                 animationDelay: 100,
               ),

              const SizedBox(height: 12),

              SettingsCard(
                icon: Icons.language,
                label: context.translate((l) => l.language),
                 onTap: () => SimpleLanguagePicker.showLanguagePicker(context),
                animationDelay: 125,
              ),

              const SizedBox(height: 12),

               SettingsCard(
                 icon: Icons.font_download_outlined,
                 label: context.translate((l) => l.fontStyle),
                 onTap: () => FontPickerWidget.showFontPicker(context),
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
