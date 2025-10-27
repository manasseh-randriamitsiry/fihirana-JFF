import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/color_controller.dart';
import '../../controller/auth_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../utility/snackbar_utility.dart';
import '../hymn/edit_hymn_screen.dart';

class UserHymnsScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String displayName;

  const UserHymnsScreen({
    Key? key,
    required this.userId,
    required this.userEmail,
    required this.displayName,
  }) : super(key: key);

  @override
  State<UserHymnsScreen> createState() => _UserHymnsScreenState();
}

class _UserHymnsScreenState extends State<UserHymnsScreen> {
  final ColorController colorController = Get.find<ColorController>();
  final HymnService _hymnService = HymnService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _sortBy = 'recent'; // 'recent', 'old', 'number'

  Stream<List<Hymn>> _getHymnsStream() async* {
    // Since we're using local files, we'll load all hymns and filter them
    final allHymns = await _hymnService.searchHymns('');
    final userHymns = allHymns.where((hymn) => 
      hymn.createdByEmail == widget.userEmail
    ).toList();
    
    // Sort based on the current sort preference
    switch (_sortBy) {
      case 'recent':
        userHymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'old':
        userHymns.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'number':
        userHymns.sort((a, b) {
          final numA = int.tryParse(a.hymnNumber) ?? 0;
          final numB = int.tryParse(b.hymnNumber) ?? 0;
          return numA.compareTo(numB);
        });
        break;
    }
    
    yield userHymns;
  }

  Future<void> _deleteHymn(String hymnId) async {
    try {
      await _hymnService.deleteHymn(hymnId);
      SnackbarUtility.showSuccess(
        title: 'Fahombiazana',
        message: 'Voafafa ny hira',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Hadisoana',
        message: 'Tsy nahomby ny famafana: $e',
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Hymn hymn) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorController.backgroundColor.value,
          title: Text(
            'Hamafa hira?',
            style: TextStyle(color: colorController.textColor.value),
          ),
          content: Text(
            'Tena hamafa ny hira "${hymn.title}" ve ianao?',
            style: TextStyle(color: colorController.textColor.value),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Tsia',
                style: TextStyle(color: colorController.textColor.value),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eny', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteHymn(hymn.id);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.primaryColor.value,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.displayName,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 16,
              ),
            ),
            Text(
              widget.userEmail,
              style: TextStyle(
                color: colorController.textColor.value.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
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
                value: 'number',
                child: Text(
                  'Laharana',
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Hymn>>(
        stream: _getHymnsStream(),
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

          final hymns = snapshot.data ?? [];

          if (hymns.isEmpty) {
            return Center(
              child: Text(
                'Tsy misy hira',
                style: TextStyle(color: colorController.textColor.value),
              ),
            );
          }

          return ListView.builder(
            itemCount: hymns.length,
            itemBuilder: (context, index) {
              final hymn = hymns[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: colorController.drawerColor.value,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorController.primaryColor.value,
                    child: Text(
                      hymn.hymnNumber,
                      style: TextStyle(
                        color: colorController.backgroundColor.value,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    hymn.title,
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt),
                    style: TextStyle(
                      color: colorController.textColor.value.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: colorController.iconColor.value,
                        ),
                        onPressed: () =>
                            Get.to(() => EditHymnScreen(hymn: hymn)),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _showDeleteConfirmation(context, hymn),
                      ),
                    ],
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
