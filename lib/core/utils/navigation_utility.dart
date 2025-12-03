import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/pages/edit_hymn_screen.dart';
import 'package:fihirana/features/hymn/presentation/pages/hymn_detail_screen.dart';
import 'package:fihirana/features/favorites/presentation/pages/favorites_screen.dart';

class NavigationUtility {
  static void navigateToEditScreen(BuildContext context, Hymn hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHymnScreen(hymn: hymn),
      ),
    );
  }

  static void navigateToDetailScreen(BuildContext context, Hymn hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HymnDetailScreen(hymnId: hymn.id),
      ),
    );
  }

  static void navigateToFavorites() {
    Get.to(() => const FavoritesPage());
  }
}
