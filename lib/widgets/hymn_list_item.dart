import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../utility/navigation_utility.dart';
import '../services/hymn_service.dart'; // Import HymnService

class HymnListItem extends StatelessWidget {
  final Hymn hymn;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onFavoritePressed;
  final HymnService _hymnService = HymnService();

  HymnListItem({
    Key? key,
    required this.hymn,
    required this.textColor,
    required this.backgroundColor,
    required this.onFavoritePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: backgroundColor,
      child: ListTile(
        title: Text(
          hymn.title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: hymn.verses.isNotEmpty
            ? Text(
                hymn.verses[0],
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            hymn.hymnNumber,
            style: TextStyle(
              color: backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: StreamBuilder<Map<String, String>>(
          stream: _hymnService.getFavoriteStatusStream(),
          builder: (context, snapshot) {
            final favoriteStatus = snapshot.data?[hymn.id] ?? '';
            final isFavorite = favoriteStatus.isNotEmpty;
            
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? (favoriteStatus == 'cloud' ? Colors.red : Colors.blue)
                    : textColor,
              ),
              onPressed: onFavoritePressed,
            );
          },
        ),
        onTap: () => NavigationUtility.navigateToDetailScreen(context, hymn),
      ),
    );
  }
}
