import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/history_controller.dart';
import '../../controller/color_controller.dart';
import '../hymn/hymn_detail_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  // Use find instead of put to get the existing instance
  final HistoryController historyController = Get.find<HistoryController>();
  final ColorController colorController = Get.find<ColorController>();

  HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.primaryColor.value,
        title: Text(
          'Tantara',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_outlined,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: colorController.iconColor.value,
            ),
            onPressed: () => _showClearHistoryDialog(context),
          ),
        ],
      ),
      body: Obx(
        () => historyController.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: colorController.primaryColor.value,
                ),
              )
            : historyController.userHistory.isEmpty
                ? Center(
                    child: Text(
                      'Tsy misy tantara',
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: historyController.userHistory.length,
                    itemBuilder: (context, index) {
                      final history = historyController.userHistory[index];
                      return Card(
                        color: colorController.drawerColor.value,
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(
                            '${history['number']} - ${history['title']}',
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(history['timestamp']),
                            style: TextStyle(
                              color: colorController.textColor.value.withOpacity(0.7),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: colorController.iconColor.value,
                          ),
                          onTap: () => Get.to(
                            () => HymnDetailScreen(hymnId: history['hymnId']),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorController.backgroundColor.value,
          title: Text(
            'Hamafa ny tantara?',
            style: TextStyle(color: colorController.textColor.value),
          ),
          content: Text(
            'Tena te hamafa ny tantaran\'ny hira rehetra ve ianao?',
            style: TextStyle(color: colorController.textColor.value),
          ),
          actions: [
            TextButton(
              child: Text(
                'Tsia',
                style: TextStyle(color: colorController.textColor.value),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Eny',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                historyController.clearHistory();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
