import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:fihirana/core/utils/translation_service.dart';
import 'package:fihirana/core/error/error_handler.dart';
import 'package:fihirana/features/history/domain/usecases/load_user_history_usecase.dart';
import 'package:fihirana/features/history/domain/usecases/add_to_history_usecase.dart';
import 'package:fihirana/features/history/domain/usecases/delete_selected_history_items_usecase.dart';
import 'package:fihirana/features/history/domain/usecases/clear_history_usecase.dart';


class HistoryController extends GetxController {
  final LoadUserHistoryUseCase _loadUserHistoryUseCase;
  final AddToHistoryUseCase _addToHistoryUseCase;
  // ignore: unused_field
  final DeleteSelectedHistoryItemsUseCase _deleteSelectedHistoryItemsUseCase;
  final ClearHistoryUseCase _clearHistoryUseCase;

  // Keep direct access for complex operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: unused_field
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();

  HistoryController({
    required LoadUserHistoryUseCase loadUserHistoryUseCase,
    required AddToHistoryUseCase addToHistoryUseCase,
    required DeleteSelectedHistoryItemsUseCase deleteSelectedHistoryItemsUseCase,
    required ClearHistoryUseCase clearHistoryUseCase,
  }) : _loadUserHistoryUseCase = loadUserHistoryUseCase,
       _addToHistoryUseCase = addToHistoryUseCase,
       _deleteSelectedHistoryItemsUseCase = deleteSelectedHistoryItemsUseCase,
       _clearHistoryUseCase = clearHistoryUseCase;

  final RxList<Map<String, dynamic>> userHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSelectionMode = false.obs;
  final RxList<String> selectedItems = <String>[].obs;

  static const String _localHistoryKey = 'local_hymn_history';

  @override
  void onInit() {
    super.onInit();
    loadUserHistory();

    _auth.authStateChanges().listen((User? user) {
      loadUserHistory();
    });
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedItems.clear();
    }
  }

  void toggleItemSelection(String id) {
    if (selectedItems.contains(id)) {
      selectedItems.remove(id);
    } else {
      selectedItems.add(id);
    }
    if (selectedItems.isEmpty && isSelectionMode.value) {
      toggleSelectionMode();
    }
  }

  Future<void> deleteSelectedItems() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;

      if (user != null) {
        final batch = _firestore.batch();
        for (String id in selectedItems) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('history')
              .doc(id);
          batch.delete(docRef);
        }
        await batch.commit();
      } else {
        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> localHistory = [];
        String? historyJson = prefs.getString(_localHistoryKey);
        if (historyJson != null) {
          localHistory = List<Map<String, dynamic>>.from(
              jsonDecode(historyJson).map((x) => Map<String, dynamic>.from(x)));
          localHistory
              .removeWhere((item) => selectedItems.contains(item['id']));
          await prefs.setString(_localHistoryKey, jsonEncode(localHistory));
        }
      }

      userHistory.removeWhere((item) => selectedItems.contains(item['id']));
      selectedItems.clear();
      isSelectionMode.value = false;

// Get the translation service
      final translationService = TranslationService();

      Get.snackbar(
        await translationService.translate(text: 'Success', sourceLanguage: 'en', targetLanguage: 'en'),
        await translationService.translate(text: 'History deleted successfully', sourceLanguage: 'en', targetLanguage: 'en'),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
} catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserHistory() async {
    try {
      isLoading.value = true;
      final historyItems = await _loadUserHistoryUseCase();
      userHistory.value = historyItems.map((item) => item.toMap()).toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToHistory(String hymnId, String title, String number) async {
    try {
      await _addToHistoryUseCase(hymnId, title, number);
      await loadUserHistory();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  Future<void> clearHistory() async {
    try {
      await _clearHistoryUseCase();
      userHistory.clear();

      final translationService = TranslationService();
      Get.snackbar(
        await translationService.translate(text: 'Success', sourceLanguage: 'en', targetLanguage: 'en'),
        await translationService.translate(text: 'History cleared successfully', sourceLanguage: 'en', targetLanguage: 'en'),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }
}
