import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../hymn/hymn_detail_screen.dart';

class FavoritesPage extends StatelessWidget {
  final HymnService _hymnService = HymnService();
  final ColorController colorController = Get.find<ColorController>();
  FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
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
      body: StreamBuilder<List<Hymn>>(
        stream: _hymnService.getFavoriteHymnsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteHymns.length,
              itemBuilder: (context, index) {
                final hymn = favoriteHymns[index];
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
                      trailing: StreamBuilder<List<String>>(
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
    );
  }
}
