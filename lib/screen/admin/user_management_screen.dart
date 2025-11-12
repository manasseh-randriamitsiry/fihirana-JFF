import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.primaryColor.value,
        title: Text(
          l10n.userManagement,
          style: TextStyle(color: colorController.textColor.value),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.sort,
              color: colorController.iconColor.value,
            ),
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
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ),
              PopupMenuItem<String>(
                value: 'old',
                child: Text(
                  l10n.oldest,
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ),
              PopupMenuItem<String>(
                value: 'songs',
                child: Text(
                  l10n.sortBySongs,
                  style: TextStyle(color: colorController.textColor.value),
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
                style: TextStyle(color: colorController.textColor.value),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                l10n.noUsers,
                style: TextStyle(color: colorController.textColor.value),
              ),
            );
          }

          return ListView.builder(
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
              final createdAt = userData['createdAt'] as Timestamp?;
              final hymnCount = userData['hymnCount'] as int? ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: colorController.drawerColor.value,
                child: InkWell(
                  onTap: () => Get.to(() => UserHymnsScreen(
                        userId: userId,
                        userEmail: email,
                        displayName: displayName,
                      )),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: photoURL != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(photoURL),
                                  backgroundColor: Colors.transparent,
                                )
                              : CircleAvatar(
                                  backgroundColor:
                                      colorController.primaryColor.value,
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: TextStyle(
                                        color: colorController.textColor.value),
                                  ),
                                ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    color: colorController.textColor.value,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorController.primaryColor.value,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.hymnCount(hymnCount),
                                  style: TextStyle(
                                    color: colorController.textColor.value,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: TextStyle(
                                  color: colorController.textColor.value
                                      .withOpacity(0.7),
                                ),
                              ),
                              if (lastLogin != null)
                                Text(
                                  '${l10n.lastLogin}: ${DateFormat('dd/MM/yyyy HH:mm').format(lastLogin.toDate())}',
                                  style: TextStyle(
                                    color: colorController.textColor.value
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              if (createdAt != null)
                                Text(
                                  '${l10n.registered}: ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}',
                                  style: TextStyle(
                                    color: colorController.textColor.value
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Switch(
                            value: canAddSongs,
                            onChanged: (value) => _authController
                                .updateUserPermission(userId, value),
                            activeThumbColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
