import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/hymn.dart';
import '../utility/navigation_utility.dart';
import '../services/hymn_service.dart';
import '../services/audio_service.dart';
import '../l10n/app_localizations.dart';

class HymnListItem extends StatefulWidget {
  final Hymn hymn;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onMusicPressed;
  final bool isFirebaseHymn;

  const HymnListItem({
    super.key,
    required this.hymn,
    required this.textColor,
    required this.backgroundColor,
    required this.onFavoritePressed,
    this.onMusicPressed,
    this.isFirebaseHymn = false,
  });

  @override
  State<HymnListItem> createState() => _HymnListItemState();
}

class _HymnListItemState extends State<HymnListItem> {
  final HymnService _hymnService = HymnService();
  final AudioService _audioService = AudioService.instance;
  bool _hasAudio = false;
  bool _audioChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAudioAvailability();
  }

  Future<void> _checkAudioAvailability() async {
    if (widget.onMusicPressed != null) {
      final hasAudio = await _audioService.checkAudioFileExists(widget.hymn.id);
      if (mounted) {
        setState(() {
          _hasAudio = hasAudio;
          _audioChecked = true;
        });
      }
    } else {
      setState(() {
        _audioChecked = true;
      });
    }
  }

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
              backgroundColor: widget.backgroundColor,
              title: Text(
                l10n.deleteHymnQuestion,
                style: TextStyle(color: widget.textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.confirmDeleteHymn(widget.hymn.title),
                    style: TextStyle(color: widget.textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    style: TextStyle(color: widget.textColor),
                    decoration: InputDecoration(
                      hintText: l10n.yesLowercase,
                      hintStyle: TextStyle(color: widget.textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: widget.textColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: widget.textColor),
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
                  child: Text(l10n.cancel, style: TextStyle(color: widget.textColor)),
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
          backgroundColor: widget.backgroundColor,
          title:
              Text(l10n.deleteHymnQuestion, style: TextStyle(color: widget.textColor)),
          content: Text(
            l10n.confirmDeleteHymn(widget.hymn.title),
            style: TextStyle(color: widget.textColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.no, style: TextStyle(color: widget.textColor)),
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
                  await _hymnService.deleteHymn(widget.hymn.id);
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
        color: widget.backgroundColor,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            widget.hymn.title,
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.hymn.verses.isNotEmpty)
                Text(
                  widget.hymn.verses[0],
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (isAdmin && widget.isFirebaseHymn)
                Text(
                  l10n.createdByLabel(
                      widget.hymn.createdBy,
                      widget.hymn.createdByEmail != null
                          ? ' (${widget.hymn.createdByEmail})'
                          : ''),
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.5),
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
              widget.hymn.hymnNumber,
              style: TextStyle(
                color: widget.backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onMusicPressed != null && _audioChecked && _hasAudio)
                Obx(() {
                  final isPlaying = _audioService.isHymnPlaying(widget.hymn.id);
                  print('Hymn ${widget.hymn.id} playing status: $isPlaying');
                  return IconButton(
                    onPressed: widget.onMusicPressed,
                    style: IconButton.styleFrom(
                      backgroundColor: isPlaying
                          ? widget.textColor.withOpacity(0.2)
                          : widget.backgroundColor,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: isPlaying
                              ? (Theme.of(context).colorScheme.primary)
                              : widget.textColor,
                          size: 20,
                        ),
                        if (isPlaying)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              StreamBuilder<Map<String, String>>(
                stream: _hymnService.getFavoriteStatusStream(),
                builder: (context, snapshot) {
                  final favoriteStatus = snapshot.data?[widget.hymn.id] ?? '';
                  final isFavorite = favoriteStatus.isNotEmpty;

                  return IconButton(
                    onPressed: widget.onFavoritePressed,
                    style: IconButton.styleFrom(
                      backgroundColor: widget.backgroundColor,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? (favoriteStatus == 'cloud'
                              ? Colors.red
                              : Colors.blue)
                          : widget.textColor,
                      size: 20,
                    ),
                  );
                },
              ),
              if (widget.isFirebaseHymn &&
                  isLoggedIn &&
                  (widget.hymn.createdByEmail == user.email || isAdmin))
                IconButton(
                  onPressed: () =>
                      NavigationUtility.navigateToEditScreen(context, widget.hymn),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.backgroundColor,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: Icon(Icons.edit, color: widget.textColor, size: 20),
                ),
              if (widget.isFirebaseHymn &&
                  isLoggedIn &&
                  (widget.hymn.createdByEmail == user.email || isAdmin))
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.backgroundColor,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                ),
            ],
          ),
          onTap: () => NavigationUtility.navigateToDetailScreen(context, widget.hymn),
        ),
      ),
    );
  }
}
