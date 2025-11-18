import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/hymn_controller.dart';
import '../../widgets/hymn_list_item.dart';
import '../../widgets/hymn_search_field.dart';
import '../../widgets/language_picker_widget.dart';
import '../../widgets/compact_audio_player_widget.dart';
import '../../utility/navigation_utility.dart';
import '../../services/version_check_service.dart';
import '../../services/audio_service.dart';
import '../../services/hymn_service.dart';
import '../../models/hymn.dart';
import '../../l10n/app_localizations.dart';

class AccueilScreen extends StatefulWidget {
  final Function() openDrawer;

  const AccueilScreen({
    super.key,
    required this.openDrawer,
  });

  @override
  AccueilScreenState createState() => AccueilScreenState();
}

class AccueilScreenState extends State<AccueilScreen> {
  final HymnController _hymnController = Get.put(HymnController());
  bool _updateAvailable = false;

  void _showAudioPlayerDialog(Hymn hymn) {
    final ColorController colorController = Get.find<ColorController>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colorController.backgroundColor.value,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Audio Player',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorController.textColor.value,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: colorController.iconColor.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CompactAudioPlayerWidget(hymn: hymn),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrentPlayingDialog() async {
    final audioService = AudioService.instance;
    final currentHymnId = audioService.currentPlayingHymnId;
    
    if (currentHymnId.isEmpty) return;
    
    // Get the hymn data
    final hymnService = HymnService();
    final hymn = await hymnService.getHymnById(currentHymnId);
    
    if (hymn != null && context.mounted) {
      _showAudioPlayerDialog(hymn);
    }
  }

  @override
  void initState() {
    super.initState();

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateAvailable =
          await VersionCheckService.checkForUpdateManually();
      if (mounted) {
        setState(() {
          _updateAvailable = updateAvailable;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.checkUpdateError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Obx(() {
        final textColor = colorController.textColor.value;
        final accentColor = colorController.accentColor.value;
        final backgroundColor = colorController.backgroundColor.value;
        final iconColor = colorController.iconColor.value;
        final defaultTextStyle = TextStyle(color: textColor, inherit: true);

        return NeumorphicTheme(
          themeMode: colorController.themeMode,
          theme: colorController.getNeumorphicLightTheme(),
          darkTheme: colorController.getNeumorphicDarkTheme(),
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                key: const ValueKey('menu_button'),
                icon: Icon(Icons.menu, color: iconColor),
                onPressed: widget.openDrawer,
              ),
              title: Text(
                AppLocalizations.of(context)!.appTitleShort,
                style: defaultTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              actions: [
                if (_updateAvailable)
                  IconButton(
                    key: const ValueKey('update_button'),
                    icon: const Icon(Icons.system_update, color: Colors.orange),
                    onPressed: _checkForUpdates,
                  ),
                Obx(() {
                  final audioService = AudioService.instance;
                  final currentHymnId = audioService.currentPlayingHymnId;
                  final isPlaying = currentHymnId.isNotEmpty && audioService.isPlaying;
                  
                  return IconButton(
                    key: const ValueKey('now_playing_button'),
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.play_circle,
                          color: isPlaying ? Theme.of(context).colorScheme.primary : iconColor,
                        ),
                        if (isPlaying)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: backgroundColor,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: isPlaying ? () => _showCurrentPlayingDialog() : null,
                  );
                }),
                IconButton(
                  key: const ValueKey('language_button'),
                  icon: Icon(Icons.language, color: iconColor),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const LanguagePickerDialog(),
                    );
                  },
                ),
                IconButton(
                  key: const ValueKey('favorites_button'),
                  icon: Icon(Icons.favorite, color: iconColor),
                  onPressed: () => NavigationUtility.navigateToFavorites(),
                ),
              ],
            ),
            body: Column(
              children: [
                HymnSearchField(
                  controller: _hymnController.searchController,
                  defaultTextStyle: defaultTextStyle,
                  textColor: textColor,
                  iconColor: iconColor,
                  backgroundColor: backgroundColor,
                  onChanged: () => setState(() {}),
                ),
                Expanded(
                  child: StreamBuilder<List<Hymn>>(
                    stream: _hymnController.hymnsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Nisy olana: ${snapshot.error}',
                            style: defaultTextStyle,
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final hymns =
                          _hymnController.filterHymnList(snapshot.data ?? []);
                      if (hymns.isEmpty) {
                        return Center(
                          child: Text(
                            'Tsy misy hira',
                            style: defaultTextStyle,
                          ),
                        );
                      }

                      return StreamBuilder<Map<String, String>>(
                        stream: _hymnController.getFavoriteStatusStream(),
                        builder: (context, favoriteSnapshot) {
                          return ListView.builder(
                            itemCount: hymns.length,
                            itemBuilder: (context, index) {
                              final hymn = hymns[index];
                              return HymnListItem(
                                key: ValueKey(hymn.id),
                                hymn: hymn,
                                textColor: textColor,
                                backgroundColor: backgroundColor,
                                onFavoritePressed: () =>
                                    _hymnController.toggleFavorite(hymn),
                                onMusicPressed: () => _showAudioPlayerDialog(hymn),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}