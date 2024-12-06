import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/color_controller.dart';
import '../../controller/auth_controller.dart';
import './user_hymns_screen.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ColorController colorController = Get.find<ColorController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _sortBy = 'recent'; // 'recent', 'old', 'songs'

  Stream<List<Map<String, dynamic>>> _getUsersWithHymnCount() {
    return _firestore.collection('users').snapshots().asyncMap((userSnapshot) async {
      List<Map<String, dynamic>> usersWithCount = [];
      
      for (var doc in userSnapshot.docs) {
        final userData = doc.data();
        // Get hymn count for each user
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

      // Sort the users based on selected criteria
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
          usersWithCount.sort((a, b) => (b['hymnCount'] as int)
              .compareTo(a['hymnCount'] as int));
          break;
      }

      return usersWithCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authController.isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            'Tsy mahazo alalana ianao',
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
          'Fitantanana mpampiasa',
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
                  'Vaovao indrindra',
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ),
              PopupMenuItem<String>(
                value: 'old',
                child: Text(
                  'Taloha indrindra',
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ),
              PopupMenuItem<String>(
                value: 'songs',
                child: Text(
                  'Isan\'ny hira',
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
                'Nisy hadisoana: ${snapshot.error}',
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
                'Tsy misy mpampiasa',
                style: TextStyle(color: colorController.textColor.value),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index];
              final userId = userData['id'] as String;
              final email = userData['email'] as String? ?? 'Tsy misy mailaka';
              final displayName = userData['displayName'] as String? ?? 'Unknown User';
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
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: TextStyle(color: colorController.textColor.value),
                                  ),
                                  backgroundColor: colorController.primaryColor.value,
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
                                  '$hymnCount hira',
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
                                  color: colorController.textColor.value.withOpacity(0.7),
                                ),
                              ),
                              if (lastLogin != null)
                                Text(
                                  'Niditra farany: ${DateFormat('dd/MM/yyyy HH:mm').format(lastLogin.toDate())}',
                                  style: TextStyle(
                                    color: colorController.textColor.value.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              if (createdAt != null)
                                Text(
                                  'Nisoratra: ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}',
                                  style: TextStyle(
                                    color: colorController.textColor.value.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Switch(
                            value: canAddSongs,
                            onChanged: (value) => _authController.updateUserPermission(userId, value),
                            activeColor: Colors.green,
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
