import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../services/audio_service.dart';
import '../hymn/hymn_detail_screen.dart';
import '../../widgets/compact_audio_player_widget.dart';
import '../../widgets/lightweight_audio_player_widget.dart';

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

  void _showAudioPlayerDialog(Hymn hymn) {
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
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Tiana', 
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_outlined,
            color: colorController.iconColor.value,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Neumorphic(
              style: NeumorphicStyle(
                color: colorController.backgroundColor.value,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
                depth: 4,
                intensity: 0.8,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Karohy ny hira tiana...',
                  hintStyle: TextStyle(color: colorController.iconColor.value.withOpacity(0.6)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorController.iconColor.value,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorController.primaryColor.value,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Olana: ${snapshot.error}',
                      style: TextStyle(color: colorController.textColor.value),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Mbola tsy misy hira tiana',
                      style: TextStyle(color: colorController.textColor.value),
                    ),
                  );
                } else {
                  final favoriteHymns = snapshot.data!;
                  // Filter hymns based on search query
                  final filteredHymns = _searchQuery.isEmpty
                      ? favoriteHymns
                      : favoriteHymns.where((hymn) {
                          return hymn.title.toLowerCase().contains(_searchQuery) ||
                                 hymn.hymnNumber.toLowerCase().contains(_searchQuery);
                        }).toList();
                  
                  if (filteredHymns.isEmpty) {
                    return Center(
                      child: Text(
                        'Tsy misy hira tiana mitovy amin\'ny karohy',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                    );
                  }
                  
                  return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredHymns.length,
              itemBuilder: (context, index) {
                final hymn = filteredHymns[index];
                
                // Check audio availability when item is built
                if (!_checkedAudioHymns.contains(hymn.id)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _checkAudioAvailability(hymn.id);
                  });
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      color: colorController.backgroundColor.value,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
                      depth: 4,
                      intensity: 0.8,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Neumorphic(
                        style: NeumorphicStyle(
                          color: colorController.primaryColor.value,
                          boxShape: NeumorphicBoxShape.circle(),
                          depth: 2,
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Text(
                            hymn.hymnNumber,
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        hymn.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorController.textColor.value,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Audio button
                          if (_audioAvailability[hymn.id] == true)
                            Obx(() {
                              final isPlaying = _audioService.isHymnPlaying(hymn.id);
                              return NeumorphicButton(
                                style: NeumorphicStyle(
                                  color: isPlaying 
                                      ? colorController.primaryColor.value.withOpacity(0.2)
                                      : colorController.backgroundColor.value,
                                  boxShape: NeumorphicBoxShape.circle(),
                                  depth: 2,
                                ),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.music_note,
                                      color: isPlaying 
                                          ? colorController.primaryColor.value
                                          : colorController.iconColor.value,
                                      size: 20,
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
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onPressed: () => _showAudioPlayerDialog(hymn),
                              );
                            }),
                          const SizedBox(width: 8),
                          // Favorite button
                          StreamBuilder<List<String>>(
                            stream: _hymnService.getFavoriteHymnIdsStream(),
                            builder: (context, favoriteSnapshot) {
                              final isFavorite =
                                  favoriteSnapshot.data?.contains(hymn.id) ?? false;
                              return NeumorphicButton(
                                style: NeumorphicStyle(
                                  color: colorController.backgroundColor.value,
                                  boxShape: NeumorphicBoxShape.circle(),
                                  depth: 2,
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : colorController.iconColor.value,
                                ),
                                onPressed: () {
                                  _hymnService.toggleFavorite(hymn);
                                },
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
                  ),
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
