import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hymn.dart';
import '../utility/navigation_utility.dart';
import '../services/hymn_service.dart';
import '../l10n/app_localizations.dart';

class HymnListItem extends StatelessWidget {
  final Hymn hymn;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onFavoritePressed;
  final bool isFirebaseHymn;
  final HymnService _hymnService = HymnService();

  HymnListItem({
    super.key,
    required this.hymn,
    required this.textColor,
    required this.backgroundColor,
    required this.onFavoritePressed,
    this.isFirebaseHymn = false,
  });

  Future<bool> _confirmDeletion(BuildContext context) async {
    final confirmationController = TextEditingController();
    bool isConfirmed = false;
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              title: Text(
                l10n.deleteHymnQuestion,
                style: TextStyle(color: textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.confirmDeleteHymn(hymn.title),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: l10n.yesLowercase,
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: textColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.toLowerCase() == 'eny') {
                        isConfirmed = true;
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.typeYesToConfirm,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancel, style: TextStyle(color: textColor)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(l10n.delete,
                      style: const TextStyle(color: Colors.red)),
                  onPressed: () {
                    if (confirmationController.text.toLowerCase() == 'eny') {
                      isConfirmed = true;
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.typeYesToConfirm,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    return isConfirmed;
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title:
              Text(l10n.deleteHymnQuestion, style: TextStyle(color: textColor)),
          content: Text(
            l10n.confirmDeleteHymn(hymn.title),
            style: TextStyle(color: textColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.no, style: TextStyle(color: textColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(l10n.yes, style: const TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();

                final confirmed = await _confirmDeletion(context);

                if (!confirmed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteHymnFailed),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _hymnService.deleteHymn(hymn.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.hymnDeletedSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isAdmin = user?.email == 'manassehrandriamitsiry@gmail.com';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: backgroundColor,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            hymn.title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hymn.verses.isNotEmpty)
                Text(
                  hymn.verses[0],
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (isAdmin && isFirebaseHymn)
                Text(
                  l10n.createdByLabel(
                      hymn.createdBy,
                      hymn.createdByEmail != null
                          ? ' (${hymn.createdByEmail})'
                          : ''),
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: 25,
            child: Text(
              hymn.hymnNumber,
              style: TextStyle(
                color: backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Map<String, String>>(
                stream: _hymnService.getFavoriteStatusStream(),
                builder: (context, snapshot) {
                  final favoriteStatus = snapshot.data?[hymn.id] ?? '';
                  final isFavorite = favoriteStatus.isNotEmpty;

                  return IconButton(
                    onPressed: onFavoritePressed,
                    style: IconButton.styleFrom(
                      backgroundColor: backgroundColor,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? (favoriteStatus == 'cloud'
                              ? Colors.red
                              : Colors.blue)
                          : textColor,
                      size: 20,
                    ),
                  );
                },
              ),
              if (isFirebaseHymn &&
                  isLoggedIn &&
                  (hymn.createdByEmail == user.email || isAdmin))
                IconButton(
                  onPressed: () =>
                      NavigationUtility.navigateToEditScreen(context, hymn),
                  style: IconButton.styleFrom(
                    backgroundColor: backgroundColor,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: Icon(Icons.edit, color: textColor, size: 20),
                ),
              if (isFirebaseHymn &&
                  isLoggedIn &&
                  (hymn.createdByEmail == user.email || isAdmin))
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: IconButton.styleFrom(
                    backgroundColor: backgroundColor,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                ),
            ],
          ),
          onTap: () => NavigationUtility.navigateToDetailScreen(context, hymn),
        ),
      ),
    );
  }
}
