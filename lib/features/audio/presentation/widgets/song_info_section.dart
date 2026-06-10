import 'package:flutter/material.dart';

class SongInfoSection extends StatelessWidget {
  final String title;
  final String hymnNumber;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const SongInfoSection({
    super.key,
    required this.title,
    required this.hymnNumber,
    required this.isFavorite,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    const primaryTextColor = Colors.white;
    const secondaryTextColor = Colors.white70;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Hymn $hymnNumber',
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: onToggleFavorite,
          ),
        ),
      ],
    );
  }
}
