import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../services/audio_service.dart';
import '../hymn/hymn_detail_screen.dart';
import '../../widgets/lightweight_audio_player_widget.dart';
import '../../l10n/app_localizations.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final HymnService _hymnService = HymnService();
  final ColorController colorController = Get.find<ColorController>();
  final AudioService _audioService = AudioService.instance;
  final Map<String, bool> _audioAvailability = {};
  final Set<String> _checkedAudioHymns = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showAudioPlayerDialog(AppLocalizations l10n, Hymn hymn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colorController.backgroundColor.value,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.audioPlayer,
                      style: TextStyle(
                        fontSize: 20,
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
                LightweightAudioPlayerWidget(
                  hymn: hymn,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkAudioAvailability(String hymnId) async {
    if (!_checkedAudioHymns.contains(hymnId)) {
      _checkedAudioHymns.add(hymnId);
      final hasAudio = await _audioService.checkAudioFileExists(hymnId);
      if (mounted) {
        setState(() {
          _audioAvailability[hymnId] = hasAudio;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.favorites,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorController.iconColor.value,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorController.backgroundColor.value,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorController.textColor.value.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: l10n.searchFavoriteSongsHint,
                  hintStyle: TextStyle(
                    color:
                        colorController.iconColor.value.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorController.iconColor.value,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorController.iconColor.value,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: TextStyle(
                  color: colorController.textColor.value,
                ),
              ),
            ),
          ),
          // Favorites list
          Expanded(
            child: StreamBuilder<List<Hymn>>(
              stream: _hymnService.getFavoriteHymnsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorController.primaryColor.value,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.error}: ${snapshot.error}',
                          style:
                              TextStyle(color: colorController.textColor.value),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: colorController.textColor.value
                              .withValues(alpha: 0.3),
                        )
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .scale(
                                duration: const Duration(seconds: 2),
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                curve: Curves.easeInOut),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noHymnsAddedYet,
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createFirstPlaylist,
                          style: TextStyle(
                            color: colorController.textColor.value
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final favoriteHymns = snapshot.data!;
                  // Filter hymns based on search query
                  final filteredHymns = _searchQuery.isEmpty
                      ? favoriteHymns
                      : favoriteHymns.where((hymn) {
                          return hymn.title
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              hymn.hymnNumber
                                  .toLowerCase()
                                  .contains(_searchQuery);
                        }).toList();

                  if (filteredHymns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: colorController.textColor.value
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noResults,
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    itemCount: filteredHymns.length,
                    itemBuilder: (context, index) {
                      final hymn = filteredHymns[index];

                      // Check audio availability when item is built
                      if (!_checkedAudioHymns.contains(hymn.id)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _checkAudioAvailability(hymn.id);
                        });
                      }

                      return Card(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorController.textColor.value
                                .withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        color: colorController.backgroundColor.value,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorController.primaryColor.value
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorController.primaryColor.value
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                hymn.hymnNumber,
                                style: TextStyle(
                                  color: colorController.primaryColor.value,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            hymn.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorController.textColor.value,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Audio button
                              if (_audioAvailability[hymn.id] == true)
                                Obx(() {
                                  final isPlaying =
                                      _audioService.isHymnPlaying(hymn.id);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isPlaying
                                          ? colorController.primaryColor.value
                                              .withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Stack(
                                        children: [
                                          Icon(
                                            Icons.music_note,
                                            color: isPlaying
                                                ? colorController
                                                    .primaryColor.value
                                                : colorController
                                                    .iconColor.value,
                                            size: 22,
                                          ),
                                          if (isPlaying)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      onPressed: () =>
                                          _showAudioPlayerDialog(l10n, hymn),
                                      tooltip: l10n.playAudio,
                                    ),
                                  );
                                }),
                              // Favorite button
                              StreamBuilder<List<String>>(
                                stream: _hymnService.getFavoriteHymnIdsStream(),
                                builder: (context, favoriteSnapshot) {
                                  final isFavorite = favoriteSnapshot.data
                                          ?.contains(hymn.id) ??
                                      false;
                                  return IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.red
                                          : colorController.iconColor.value,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      _hymnService.toggleFavorite(hymn);
                                    },
                                    tooltip: isFavorite
                                        ? l10n.removeFromFavorites
                                        : l10n.addToFavorites,
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HymnDetailScreen(hymnId: hymn.id),
                              ),
                            );
                          },
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                          .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 300.ms,
                              delay: (50 * index).ms,
                              curve: Curves.easeOut);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
