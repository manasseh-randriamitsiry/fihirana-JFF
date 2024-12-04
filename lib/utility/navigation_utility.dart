import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/hymn.dart';
import '../screen/hymn/edit_hymn_screen.dart';
import '../screen/hymn/hymn_detail_screen.dart';
import '../screen/favorite/favorites_screen.dart';

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
    Get.to(() => FavoritesPage());
  }
}
