import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          color: colorController.backgroundColor.value,
                          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
                          depth: 4,
                          intensity: 0.8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Tsy misy tantara',
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: historyController.userHistory.length,
                      itemBuilder: (context, index) {
                        final history = historyController.userHistory[index];
                        final DateTime timestamp = history['timestamp'];
                        final String formattedDate =
                            DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Neumorphic(
                            style: NeumorphicStyle(
                              color: colorController.backgroundColor.value,
                              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
                              depth: 4,
                              intensity: 0.8,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: historyController.isSelectionMode.value
                                  ? NeumorphicCheckbox(
                                      value: historyController.selectedItems
                                          .contains(history['id']),
                                      onChanged: (_) => historyController
                                          .toggleItemSelection(history['id']),
                                      style: NeumorphicCheckboxStyle(
                                        selectedColor: colorController.primaryColor.value,
                                      ),
                                    )
                                  : NeumorphicIcon(
                                      Icons.history,
                                      style: NeumorphicStyle(
                                        color: colorController.iconColor.value,
                                      ),
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
                            ),
                          ),
                        );
                      },
                    ),
        ));
  }

  void _showClearHistoryDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Neumorphic(
          style: NeumorphicStyle(
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
            depth: 6,
            intensity: 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hamafa ny tantara rehetra?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorController.textColor.value,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tsy azo averina intsony ny tantara rehefa voafafa.',
                  style: TextStyle(color: colorController.textColor.value),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NeumorphicButton(
                      onPressed: () => Get.back(),
                      style: NeumorphicStyle(
                        color: colorController.backgroundColor.value,
                        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                        depth: 2,
                      ),
                      child: Text(
                        'Tsia',
                        style: TextStyle(color: colorController.primaryColor.value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeumorphicButton(
                      onPressed: () {
                        historyController.clearHistory();
                        Get.back();
                      },
                      style: NeumorphicStyle(
                        color: Colors.red.withOpacity(0.1),
                        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                        depth: 2,
                      ),
                      child: const Text(
                        'Eny',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Neumorphic(
          style: NeumorphicStyle(
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
            depth: 6,
            intensity: 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hamafa ny tantara voafidy?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorController.textColor.value,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tsy azo averina intsony ny tantara rehefa voafafa.',
                  style: TextStyle(color: colorController.textColor.value),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NeumorphicButton(
                      onPressed: () => Get.back(),
                      style: NeumorphicStyle(
                        color: colorController.backgroundColor.value,
                        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                        depth: 2,
                      ),
                      child: Text(
                        'Tsia',
                        style: TextStyle(color: colorController.primaryColor.value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeumorphicButton(
                      onPressed: () {
                        historyController.deleteSelectedItems();
                        Get.back();
                      },
                      style: NeumorphicStyle(
                        color: Colors.red.withOpacity(0.1),
                        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                        depth: 2,
                      ),
                      child: const Text(
                        'Eny',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
