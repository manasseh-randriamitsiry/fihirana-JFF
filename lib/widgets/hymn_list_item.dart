import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hymn.dart';
import '../utility/navigation_utility.dart';
import '../services/hymn_service.dart';

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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              title: Text(
                'Hamafa hira?',
                style: TextStyle(color: textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Raha te hamafa ny hira "${hymn.title}" dia soraty hoe "eny" eo ambany',
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'eny',
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
                          const SnackBar(
                            content: Text(
                              'Soraty hoe "eny" mba hamafana',
                              style: TextStyle(color: Colors.white),
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
                  child: Text('Ajanona', style: TextStyle(color: textColor)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child:
                      const Text('Fafao', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    if (confirmationController.text.toLowerCase() == 'eny') {
                      isConfirmed = true;
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Soraty hoe "eny" mba hamafana',
                            style: TextStyle(color: Colors.white),
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
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text('Hamafa hira?', style: TextStyle(color: textColor)),
          content: Text(
            'Tena hamafa ny hira "${hymn.title}" ve ianao?',
            style: TextStyle(color: textColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tsia', style: TextStyle(color: textColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eny', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();

                final confirmed = await _confirmDeletion(context);

                if (!confirmed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tsy nahomby ny famafana.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _hymnService.deleteHymn(hymn.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voafafa ny hira'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nisy olana: $e'),
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
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isAdmin = user?.email == 'manassehrandriamitsiry@gmail.com';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 8,
          intensity: 0.65,
          surfaceIntensity: 0.25,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          color: backgroundColor,
        ),
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
                  'Nampiditra: ${hymn.createdBy}${hymn.createdByEmail != null ? ' (${hymn.createdByEmail})' : ''}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          leading: Neumorphic(
            style: NeumorphicStyle(
              depth: 4,
              intensity: 0.65,
              boxShape: const NeumorphicBoxShape.circle(),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Center(
                child: Text(
                  hymn.hymnNumber,
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

                  return NeumorphicButton(
                    onPressed: onFavoritePressed,
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.concave,
                      boxShape: const NeumorphicBoxShape.circle(),
                      depth: isFavorite ? -4 : 4,
                      intensity: 0.65,
                      color: backgroundColor,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
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
                NeumorphicButton(
                  onPressed: () =>
                      NavigationUtility.navigateToEditScreen(context, hymn),
                  style: NeumorphicStyle(
                    shape: NeumorphicShape.concave,
                    boxShape: const NeumorphicBoxShape.circle(),
                    depth: 4,
                    intensity: 0.65,
                    color: backgroundColor,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.edit, color: textColor, size: 20),
                ),
              if (isFirebaseHymn &&
                  isLoggedIn &&
                  (hymn.createdByEmail == user.email || isAdmin))
                NeumorphicButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: NeumorphicStyle(
                    shape: NeumorphicShape.concave,
                    boxShape: const NeumorphicBoxShape.circle(),
                    depth: 4,
                    intensity: 0.65,
                    color: backgroundColor,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.delete_outline,
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
