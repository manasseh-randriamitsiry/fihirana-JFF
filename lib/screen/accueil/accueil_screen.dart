import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/hymn_controller.dart';
import '../../widgets/hymn_list_item.dart';
import '../../widgets/hymn_search_field.dart';
import '../../widgets/language_picker_widget.dart';
import '../player/enhanced_audio_player_screen.dart';
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
  final Set<String> _checkedHymnIds = <String>{};

  void _showAudioPlayerDialog(Hymn hymn) {
    // Navigate to enhanced player - it will load all hymns as playlist
    AudioPlayerNavigator.navigateToEnhancedPlayer(
      context,
      hymn: hymn,
      playlist: null, // Let the enhanced player handle loading all hymns
      initialIndex: null,
    );
  }

  void _showCurrentPlayingDialog() async {
    final audioService = AudioService.instance;
    final currentHymnId = audioService.currentPlayingHymnId;

    if (currentHymnId.isEmpty) return;

    // Get hymn data
    final hymnService = HymnService();
    final hymn = await hymnService.getHymnById(currentHymnId);

    if (hymn != null && context.mounted) {
      _showAudioPlayerDialog(hymn);
    }
  }

  Future<void> _showAudioPlayerWithFirstHymn() async {
    // Get the first hymn from the current filtered list
    final hymns =
        _hymnController.filterHymnList(await _hymnController.hymnsStream.first);

    if (hymns.isNotEmpty && context.mounted) {
      _showAudioPlayerDialog(hymns.first);
    }
  }

  void _batchCheckAudioFiles(List<Hymn> hymns) {
    final audioService = AudioService.instance;
    final List<String> uncheckedIds = [];

    for (final hymn in hymns) {
      if (!_checkedHymnIds.contains(hymn.id)) {
        uncheckedIds.add(hymn.id);
      }
    }

    if (uncheckedIds.isNotEmpty) {
      // Use new cache service for efficient batch checking
      audioService.checkAudioFilesExist(uncheckedIds).then((results) {
        _checkedHymnIds.addAll(results.keys);
        print(
            'AccueilScreen: Batch checked ${uncheckedIds.length} hymns, ${results.values.where((v) => v).length} have audio');
      }).catchError((error) {
        // Silently handle errors to not affect UI
        print('Batch audio check error: $error');
      });
    }
  }

  void _preloadCommonHymns(List<Hymn> hymns) {
    // Preload first 20 hymns to improve user experience
    final commonHymnIds = hymns.take(20).map((h) => h.id).toList();
    AudioService.instance.preloadCommonHymns(commonHymnIds);
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
                  final isPlaying =
                      currentHymnId.isNotEmpty && audioService.isPlaying;

                  return IconButton(
                    key: const ValueKey('now_playing_button'),
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.play_circle,
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary
                              : iconColor,
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
                    onPressed: () async {
                      if (isPlaying) {
                        _showCurrentPlayingDialog();
                      } else {
                        await _showAudioPlayerWithFirstHymn();
                      }
                    },
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

                      // Initial batch check for first 10 items and preload common hymns
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final List<Hymn> firstTen =
                            hymns.length >= 10 ? hymns.sublist(0, 10) : hymns;
                        _batchCheckAudioFiles(firstTen);

                        // Preload common hymns in background
                        _preloadCommonHymns(hymns);
                      });

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
                                onMusicPressed: () =>
                                    _showAudioPlayerDialog(hymn),
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
