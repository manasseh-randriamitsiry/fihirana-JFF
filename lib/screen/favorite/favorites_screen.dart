import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../services/audio_service.dart';
import '../hymn/hymn_detail_screen.dart';
import '../../widgets/favorites/favorites_search_bar.dart';
import '../../widgets/favorites/favorite_hymn_card.dart';
import '../../widgets/common/mlkit_localization_provider.dart';

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
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.menu_rounded, color: colorController.iconColor.value),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
title: Text(
          context.translateWithMLKit((l) => l.favorites),
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
       body: Column(
         children: [
           // Search bar
           FavoritesSearchBar(
             controller: _searchController,
             onChanged: (value) {
               setState(() {
                 _searchQuery = value.toLowerCase();
               });
             },
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
                          '${context.translateWithMLKit((l) => l.error)}: ${snapshot.error}',
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
                          context.translateWithMLKit((l) => l.noHymnsAddedYet),
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.translateWithMLKit((l) => l.createFirstPlaylist),
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
                            context.translateWithMLKit((l) => l.noResults),
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

                       return StreamBuilder<List<String>>(
                         stream: _hymnService.getFavoriteHymnIdsStream(),
                         builder: (context, favoriteSnapshot) {
                           final isFavorite = favoriteSnapshot.data?.contains(hymn.id) ?? false;
                           final isPlaying = _audioService.isHymnPlaying(hymn.id);
                           
                           return FavoriteHymnCard(
                             hymn: hymn,
                             hasAudio: _audioAvailability[hymn.id] == true,
                             isPlaying: isPlaying,
                             isFavorite: isFavorite,
                             index: index,
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => HymnDetailScreen(hymnId: hymn.id),
                                 ),
                               );
                             },
                             onAudioPressed: () {},
                             onFavoritePressed: () {
                               _hymnService.toggleFavorite(hymn);
                             },
                           );
                         },
                       );
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
