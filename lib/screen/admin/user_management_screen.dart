import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/color_controller.dart';
import '../../controller/auth_controller.dart';
import './user_hymns_screen.dart';
import '../../l10n/app_localizations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ColorController colorController = Get.find<ColorController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _sortBy = 'recent';

  Stream<List<Map<String, dynamic>>> _getUsersWithHymnCount() {
    return _firestore
        .collection('users')
        .snapshots()
        .asyncMap((userSnapshot) async {
      List<Map<String, dynamic>> usersWithCount = [];

      for (var doc in userSnapshot.docs) {
        final userData = doc.data();

        final hymnCount = await _firestore
            .collection('hymns')
            .where('createdByEmail', isEqualTo: userData['email'])
            .count()
            .get();

        usersWithCount.add({
          'id': doc.id,
          ...userData,
          'hymnCount': hymnCount.count,
        });
      }

      switch (_sortBy) {
        case 'recent':
          usersWithCount.sort((a, b) => (b['lastLogin'] as Timestamp)
              .compareTo(a['lastLogin'] as Timestamp));
          break;
        case 'old':
          usersWithCount.sort((a, b) => (a['lastLogin'] as Timestamp)
              .compareTo(b['lastLogin'] as Timestamp));
          break;
        case 'songs':
          usersWithCount.sort((a, b) =>
              (b['hymnCount'] as int).compareTo(a['hymnCount'] as int));
          break;
      }

      return usersWithCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_authController.isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.noPermission,
            style: TextStyle(color: colorController.textColor.value),
          ),
        ),
      );
    }

    return Obx(() {
      final backgroundColor = colorController.backgroundColor.value;
      final textColor = colorController.textColor.value;
      final iconColor = colorController.iconColor.value;
      final primaryColor = colorController.primaryColor.value;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.userManagement,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: iconColor,
            ),
            onPressed: () => Get.back(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(
                Icons.sort,
                color: iconColor,
              ),
              color: backgroundColor,
              onSelected: (String value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'recent',
                  child: Text(
                    l10n.newest,
                    style: TextStyle(color: textColor),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'old',
                  child: Text(
                    l10n.oldest,
                    style: TextStyle(color: textColor),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'songs',
                  child: Text(
                    l10n.sortBySongs,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getUsersWithHymnCount(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${l10n.errorOccurred}: ${snapshot.error}',
                  style: TextStyle(color: textColor),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                            size: 64, color: textColor.withValues(alpha: 0.3))
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .scale(
                            duration: const Duration(seconds: 2),
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noUsers,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index];
                final userId = userData['id'] as String;
                final email = userData['email'] as String? ?? l10n.noEmail;
                final displayName =
                    userData['displayName'] as String? ?? l10n.unknownUser;
                final photoURL = userData['photoURL'] as String?;
                final canAddSongs = userData['canAddSongs'] as bool? ?? false;
                final lastLogin = userData['lastLogin'] as Timestamp?;
                // final createdAt = userData['createdAt'] as Timestamp?; // Unused
                final hymnCount = userData['hymnCount'] as int? ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: backgroundColor,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Get.to(() => UserHymnsScreen(
                            userId: userId,
                            userEmail: email,
                            displayName: displayName,
                          )),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: photoURL != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(photoURL),
                                      backgroundColor: Colors.transparent,
                                      radius: 24,
                                    )
                                  : CircleAvatar(
                                      backgroundColor: primaryColor,
                                      radius: 24,
                                      child: Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            color: backgroundColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: primaryColor.withValues(
                                              alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.music_note,
                                            size: 12, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$hymnCount',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 12,
                                          color:
                                              textColor.withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      if (lastLogin != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm')
                                              .format(lastLogin.toDate()),
                                          style: TextStyle(
                                            color: textColor.withValues(
                                                alpha: 0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: canAddSongs,
                                  onChanged: (value) => _authController
                                      .updateUserPermission(userId, value),
                                  activeThumbColor: Colors.green,
                                  activeTrackColor:
                                      Colors.green.withValues(alpha: 0.2),
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor:
                                      Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: 50 * index))
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: 50 * index),
                        curve: Curves.easeOut);
              },
            );
          },
        ),
      );
    });
  }
}
