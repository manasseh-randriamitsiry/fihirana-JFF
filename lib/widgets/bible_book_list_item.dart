import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class BibleBookListItem extends StatelessWidget {
  final String bookName;
  final int chapterCount;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const BibleBookListItem({
    super.key,
    required this.bookName,
    required this.chapterCount,
    required this.textColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: backgroundColor,
      child: ListTile(
        title: Text(
          bookName,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          l10n.chaptersCount(chapterCount),
          style: TextStyle(
            color: textColor.withOpacity(0.7),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            bookName.substring(0, 1),
            style: TextStyle(
              color: backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: textColor.withOpacity(0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
