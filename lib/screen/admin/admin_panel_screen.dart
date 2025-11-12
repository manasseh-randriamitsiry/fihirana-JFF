import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import './user_management_screen.dart';
import '../../l10n/app_localizations.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

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
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noAdminPermission),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedHymns() async {
    if (selectedHymns.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => isLoading = true);
    try {
      for (String hymnId in selectedHymns) {
        await _hymnService.deleteHymn(hymnId);
      }
      selectedHymns.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectedHymnsDeleted),
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
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel),
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () => Get.to(() => const UserManagementScreen()),
          ),
          if (selectedHymns.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedHymns,
            ),
        ],
      ),
      body: StreamBuilder<List<Hymn>>(
        stream: _hymnService.getFirebaseHymnsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.error}: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hymns = snapshot.data ?? [];

          hymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (hymns.isEmpty) {
            return Center(child: Text(l10n.noHymns));
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
                      Text('${l10n.createdBy}: ${hymn.createdBy}'),
                      if (hymn.createdByEmail != null)
                        Text(l10n.emailLabel(hymn.createdByEmail!)),
                      Text(
                          '${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}'),
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
