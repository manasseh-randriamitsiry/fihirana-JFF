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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HymnDetailScreen(hymnId: hymn.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutExpo;

          var scaleAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );
          
          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );

          return ScaleTransition(
            scale: scaleAnimation,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  static void navigateToFavorites() {
    Get.to(() => const FavoritesPage());
  }
}
