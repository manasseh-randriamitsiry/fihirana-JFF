import 'package:flutter/material.dart';

class AlbumArtCard extends StatelessWidget {
  final String hymnNumber;

  const AlbumArtCard({
    super.key,
    required this.hymnNumber,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFE0C09C); // Beige/Gold card color from image

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Placeholder for Hymn Image (or just the color/gradient)
            Center(
              child: Icon(
                Icons.music_note,
                size: 120,
                color: Colors.brown.withValues(alpha: 0.3),
              ),
            ),
            // Hymn Number Overlay
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$hymnNumber',
                  style: TextStyle(
                    color: Colors.brown.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}