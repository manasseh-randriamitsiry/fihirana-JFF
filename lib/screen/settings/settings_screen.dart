import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/font_picker_widget.dart';
import '../../services/audio_service.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ColorController colorController = Get.find<ColorController>();
  final AudioService _audioService = AudioService.instance;

  void _showAudioCacheDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.audioCacheManagement,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: FutureBuilder<Map<String, dynamic>>(
          future: _audioService.getCacheStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data!;
            final totalHymns = (stats['total_checked'] as int?) ?? 0;
            final withAudio = (stats['with_audio'] as int?) ?? 0;
            final withoutAudio = (stats['without_audio'] as int?) ?? 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalCachedHymns(totalHymns),
                  style: TextStyle(color: colorController.textColor.value),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.withAudio(withAudio),
                  style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.withoutAudio(withoutAudio),
                  style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.8)),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: colorController.textColor.value)),
          ),
          TextButton(
            onPressed: () async {
              await _audioService.clearExpiredCache();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.expiredCacheCleared)),
                );
              }
            },
            child: Text(l10n.clearExpired,
                style: TextStyle(color: colorController.primaryColor.value)),
          ),
          TextButton(
            onPressed: () async {
              await _audioService.clearAllCache();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.allCacheCleared)),
                );
              }
            },
            child:
                Text(l10n.clearAll, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorController.textColor.value.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    int animationDelay = 0,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: colorController.backgroundColor.value,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorController.primaryColor.value)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colorController.primaryColor.value,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorController.textColor.value.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: animationDelay),
            duration: const Duration(milliseconds: 300))
        .slideX(begin: -0.1, end: 0);
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
            _buildSectionHeader(l10n.theme)
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 400)),

            _buildSettingCard(
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

            _buildSettingCard(
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
            _buildSectionHeader(l10n.bible).animate().fadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 400)),

            _buildSettingCard(
              icon: Icons.auto_stories,
              label: l10n.dailyBibleVerse,
              onTap: () => Get.toNamed('/daily_verse_settings'),
              iconColor: Colors.purple,
              animationDelay: 250,
            ),

            // Audio Section
            _buildSectionHeader('Audio').animate().fadeIn(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 400)),

            _buildSettingCard(
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
