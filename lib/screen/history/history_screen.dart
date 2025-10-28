import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/history_controller.dart';
import '../../controller/color_controller.dart';
import '../hymn/hymn_detail_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryController historyController = Get.find<HistoryController>();
  final ColorController colorController = Get.find<ColorController>();

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: colorController.backgroundColor.value,
          appBar: AppBar(
            backgroundColor: colorController.primaryColor.value,
            title: Text(
              historyController.isSelectionMode.value
                  ? '${historyController.selectedItems.length} voafidy'
                  : 'Tantara',
              style: const TextStyle(color: Colors.white),
            ),
            leading: historyController.isSelectionMode.value
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorController.iconColor.value,
                    ),
                    onPressed: historyController.toggleSelectionMode,
                  )
                : IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_outlined,
                      color: colorController.iconColor.value,
                    ),
                    onPressed: () => Get.back(),
                  ),
            actions: [
              if (historyController.isSelectionMode.value) ...[
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorController.iconColor.value,
                  ),
                  onPressed: () => _showDeleteSelectedDialog(context),
                ),
              ] else ...[
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorController.iconColor.value,
                  ),
                  onPressed: () => _showClearHistoryDialog(context),
                ),
              ],
            ],
          ),
          body: historyController.isLoading.value
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
                        final DateTime timestamp = history['timestamp'];
                        final String formattedDate =
                            DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

                        return ListTile(
                          leading: historyController.isSelectionMode.value
                              ? Checkbox(
                                  value: historyController.selectedItems
                                      .contains(history['id']),
                                  onChanged: (_) => historyController
                                      .toggleItemSelection(history['id']),
                                  activeColor:
                                      colorController.primaryColor.value,
                                )
                              : Icon(
                                  Icons.history,
                                  color: colorController.iconColor.value,
                                ),
                          title: Text(
                            '${history['number']}',
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            formattedDate,
                            style: TextStyle(
                              color: colorController.textColor.value
                                  .withOpacity(0.7),
                            ),
                          ),
                          onTap: () {
                            if (historyController.isSelectionMode.value) {
                              historyController
                                  .toggleItemSelection(history['id']);
                            } else {
                              Get.to(() => HymnDetailScreen(
                                    hymnId: history['hymnId'],
                                  ));
                            }
                          },
                          onLongPress: () {
                            if (!historyController.isSelectionMode.value) {
                              historyController.toggleSelectionMode();
                              historyController
                                  .toggleItemSelection(history['id']);
                            }
                          },
                        );
                      },
                    ),
        ));
  }

  void _showClearHistoryDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          'Hamafa ny tantara rehetra?',
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          'Tsy azo averina intsony ny tantara rehefa voafafa.',
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            child: Text(
              'Tsia',
              style: TextStyle(color: colorController.primaryColor.value),
            ),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: const Text(
              'Eny',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              historyController.clearHistory();
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          'Hamafa ny tantara voafidy?',
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          'Tsy azo averina intsony ny tantara rehefa voafafa.',
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            child: Text(
              'Tsia',
              style: TextStyle(color: colorController.primaryColor.value),
            ),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: const Text(
              'Eny',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              historyController.deleteSelectedItems();
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
