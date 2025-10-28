import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/color_controller.dart';
import '../../controller/history_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ColorController colorController = Get.find<ColorController>();
  final HistoryController historyController = Get.find<HistoryController>();

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          'Hamafa ny tantara',
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          'Tena te hamafa ny tantara rehetra ve ianao? Tsy afaka averina io hafainganana.',
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Aoka ihany',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          TextButton(
            onPressed: () {
              historyController.clearHistory();
              Navigator.pop(context);
            },
            child: Text(
              'Hamafa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          'Fandrindrana',
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
          // User Info Section
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
                        'Ny mombamomba anao',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Anaran\'utilisateur: ${user.displayName ?? 'Tsy fantatra'}',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Mailaka: ${user.email ?? 'Tsy misy mailaka'}',
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
                        'Tsy tonta',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tsy tonta ianao amin\'izao. Ampidiro ny kaontinao mba handanjalanjana azy ireo.',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
          
          // History Settings
          Card(
            color: colorController.primaryColor.value.withOpacity(0.5),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tantara',
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
                      'Hamafa ny tantara rehetra',
                      style: TextStyle(color: colorController.textColor.value),
                    ),
                    subtitle: Text(
                      'Mamafa ny tantara rehetra misy anao',
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
          
          // Sync Information
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
                        'Fampahalalam-baovao',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ny hira tiana sy ny tantara dia voatahiry amin\'ny kaontinao Google.',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Raha miova kaonty ianao dia tsy ho very izany.',
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