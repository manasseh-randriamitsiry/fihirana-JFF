import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../widgets/drawer_widget.dart';
import './user_management_screen.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../l10n/app_localizations.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final HymnService _hymnService = HymnService();
  final ColorController _colorController = Get.find<ColorController>();
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
      if (!mounted) return;
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
      if (!mounted) return;

      selectedHymns.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectedHymnsDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final backgroundColor = _colorController.backgroundColor.value;
      final textColor = _colorController.textColor.value;
      final iconColor = _colorController.iconColor.value;
      final primaryColor = _colorController.primaryColor.value;

      return Scaffold(
        backgroundColor: backgroundColor,
        drawer: DrawerWidget(openDrawer: () {
          Get.find<ShellController>().toggleDrawer();
        }),
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: iconColor,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            l10n.adminPanel,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.people, color: iconColor),
              onPressed: () => Get.to(() => const UserManagementScreen()),
            ),
            if (selectedHymns.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelectedHymns,
              ),
          ],
        ),
        body: StreamBuilder<List<Hymn>>(
          stream: _hymnService.getFirebaseHymnsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('${l10n.error}: ${snapshot.error}',
                      style: TextStyle(color: textColor)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }

            final hymns = snapshot.data ?? [];

            hymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (hymns.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books_outlined,
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
                      l10n.noHymns,
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
              itemCount: hymns.length,
              itemBuilder: (context, index) {
                final hymn = hymns[index];
                final isSelected = selectedHymns.contains(hymn.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: backgroundColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Checkbox(
                        value: isSelected,
                        activeColor: primaryColor,
                        side:
                            BorderSide(color: textColor.withValues(alpha: 0.5)),
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
                      title: Text(
                        '${hymn.hymnNumber} - ${hymn.title}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.createdBy}: ${hymn.createdBy}',
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.7)),
                          ),
                          if (hymn.createdByEmail != null)
                            Text(
                              l10n.emailLabel(hymn.createdByEmail!),
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 12),
                            ),
                          Text(
                            '${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}',
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 12),
                          ),
                        ],
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
