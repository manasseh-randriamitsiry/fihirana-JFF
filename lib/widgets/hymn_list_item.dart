import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hymn.dart';

class HymnListItem extends StatelessWidget {
  final Hymn hymn;
  final TextStyle defaultTextStyle;
  final Color iconColor;
  final Color textColor;
  final Color accentColor;
  final bool isAdmin;
  final Map<String, String> favoriteStatuses;
  final Function(Hymn) onToggleFavorite;
  final VoidCallback onEdit;
  final Function(Hymn) onDelete;
  final Function(Hymn) onTap;
  final String Function(Hymn) getPreviewText;

  const HymnListItem({
    Key? key,
    required this.hymn,
    required this.defaultTextStyle,
    required this.iconColor,
    required this.textColor,
    required this.accentColor,
    required this.isAdmin,
    required this.favoriteStatuses,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.getPreviewText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Theme.of(context).primaryColor,
      child: ListTile(
        title: Text(
          hymn.title,
          style: defaultTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: _buildSubtitle(),
        leading: CircleAvatar(
          backgroundColor: accentColor,
          child: Text(
            hymn.hymnNumber,
            style: defaultTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                favoriteStatuses.containsKey(hymn.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: favoriteStatuses.containsKey(hymn.id)
                    ? (favoriteStatuses[hymn.id] == 'cloud'
                        ? Colors.red
                        : iconColor)
                    : iconColor,
              ),
              onPressed: () => onToggleFavorite(hymn),
            ),
            if (isAdmin) ...[
              IconButton(
                icon: Icon(Icons.edit, color: iconColor),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(hymn),
              ),
            ],
          ],
        ),
        onTap: () => onTap(hymn),
      ),
    );
  }

  Widget _buildSubtitle() {
    if (isAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nampiditra: ${hymn.createdBy}',
            style: defaultTextStyle.copyWith(
              color: textColor.withOpacity(0.7),
            ),
          ),
          if (hymn.createdAt != null)
            Text(
              'Daty: ${DateFormat('dd/MM/yyyy').format(hymn.createdAt)}',
              style: defaultTextStyle.copyWith(
                color: textColor.withOpacity(0.7),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hymn.hymnHint != null && hymn.hymnHint!.isNotEmpty)
          Text(
            hymn.hymnHint!,
            style: defaultTextStyle.copyWith(
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          getPreviewText(hymn),
          style: defaultTextStyle.copyWith(
            color: textColor.withOpacity(0.7),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
