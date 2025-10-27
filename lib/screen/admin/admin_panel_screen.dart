import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import './user_management_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final HymnService _hymnService = HymnService();
  List<String> selectedHymns = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != 'manassehrandriamitsiry@gmail.com') {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tsy manana alalana hiditra amin\'ny admin panel ianao'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedHymns() async {
    if (selectedHymns.isEmpty) return;

    setState(() => isLoading = true);
    try {
      for (String hymnId in selectedHymns) {
        await _hymnService.deleteHymn(hymnId);
      }
      selectedHymns.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voafafa daholo ny hira nosafidiana'),
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
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.people, color: Colors.white),
            onPressed: () => Get.to(() => UserManagementScreen()),
          ),
          if (selectedHymns.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedHymns,
            ),
        ],
      ),
      body: StreamBuilder<List<Hymn>>(
        stream: _hymnService.getHymnsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hymns = snapshot.data ?? [];
          
          // Sort by creation date (newest first)
          hymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (hymns.isEmpty) {
            return const Center(child: Text('Tsy misy hira'));
          }

          return ListView.builder(
            itemCount: hymns.length,
            itemBuilder: (context, index) {
              final hymn = hymns[index];
              final isSelected = selectedHymns.contains(hymn.id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedHymns.add(hymn.id);
                        } else {
                          selectedHymns.remove(hymn.id);
                        }
                      });
                    },
                  ),
                  title: Text('${hymn.hymnNumber} - ${hymn.title}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nampiditra: ${hymn.createdBy}'),
                      if (hymn.createdByEmail != null)
                        Text('Email: ${hymn.createdByEmail}'),
                      Text('Daty: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}'),
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
