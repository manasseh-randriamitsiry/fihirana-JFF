import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/color_controller.dart';
import '../../controller/history_controller.dart';
import '../../controller/language_controller.dart';
import '../../widgets/language_picker_widget.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ColorController colorController = Get.find<ColorController>();
  final HistoryController historyController = Get.find<HistoryController>();
  final LanguageController languageController = Get.find<LanguageController>();

  void _showClearHistoryDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          l10n.confirmDelete,
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          l10n.confirmDelete,
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          TextButton(
            onPressed: () {
              historyController.clearHistory();
              Navigator.pop(context);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        children: [
          // Language Picker Section
          const LanguagePickerWidget(),
          
          const SizedBox(height: 16),

          Obx(() {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return Card(
                color: colorController.primaryColor.value.withOpacity(0.5),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Profile',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Username: ${user.displayName ?? 'Unknown'}',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Email: ${user.email ?? 'No email'}',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID: ${user.uid}',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Card(
                color: colorController.primaryColor.value.withOpacity(0.5),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not Logged In',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You are not logged in. Sign in to your account to access all features.',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),

          Card(
            color: colorController.primaryColor.value.withOpacity(0.5),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.history,
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Clear all history',
                      style: TextStyle(color: colorController.textColor.value),
                    ),
                    subtitle: Text(
                      'Remove all your history',
                      style: TextStyle(
                        color: colorController.textColor.value.withOpacity(0.7),
                      ),
                    ),
                    trailing: Icon(
                      Icons.delete,
                      color: colorController.iconColor.value,
                    ),
                    onTap: _showClearHistoryDialog,
                  ),
                ],
              ),
            ),
          ),

          Obx(() {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return Card(
                color: colorController.primaryColor.value.withOpacity(0.5),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Information',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your favorite hymns and history are saved to your Google account.',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'This will not be lost if you change accounts.',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Container();
            }
          }),
        ],
      ),
    );
  }
}