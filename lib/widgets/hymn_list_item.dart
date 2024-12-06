import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../utility/navigation_utility.dart';
import '../services/hymn_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class HymnListItem extends StatelessWidget {
  final Hymn hymn;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onFavoritePressed;
  final HymnService _hymnService = HymnService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  HymnListItem({
    Key? key,
    required this.hymn,
    required this.textColor,
    required this.backgroundColor,
    required this.onFavoritePressed,
  }) : super(key: key);

  Future<bool> _authenticateUser(BuildContext context) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        // Device doesn't support biometric authentication
        // Fallback to device password/PIN
        return await _localAuth.authenticate(
          localizedReason: 'Ampidiro ny tenimiafina na ny PIN',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
      }

      // Check available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        // No biometrics enrolled, fallback to device password/PIN
        return await _localAuth.authenticate(
          localizedReason: 'Ampidiro ny tenimiafina na ny PIN',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
      }

      // Authenticate with biometrics
      return await _localAuth.authenticate(
        localizedReason: 'Ampidiro ny fanamarinanao hamafa ny hira',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      if (e.toString().contains(auth_error.notAvailable)) {
        // Biometric auth not available, fallback to device password/PIN
        return await _localAuth.authenticate(
          localizedReason: 'Ampidiro ny tenimiafina na ny PIN',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
      }
      return false;
    }
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
              child: Text('Eny', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();

                // Request biometric authentication
                final authenticated = await _authenticateUser(context);

                if (!authenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tsy nahomby ny fanamarinana'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _hymnService.deleteHymn(hymn.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
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
            if (isAdmin && hymn.createdBy != null)
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Map<String, String>>(
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
            if (isLoggedIn && hymn.createdByEmail == user.email ||
                user?.email == 'manassehrandriamitsiry@gmail.com')
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context),
              ),
          ],
        ),
        onTap: () => NavigationUtility.navigateToDetailScreen(context, hymn),
      ),
    );
  }
}
