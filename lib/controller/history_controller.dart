import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/firebase_sync_service.dart';
import '../l10n/app_localizations.dart';

class HistoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();

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

      // Get the localization instance
      final l10n = AppLocalizations.of(Get.context!)!;

      Get.snackbar(
        l10n.success,
        l10n.deleteHistorySuccess,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(Get.context!)!;
      Get.snackbar(
        l10n.error,
        l10n.deleteHistoryError,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserHistory() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;

      if (user != null) {
        final firebaseHistory =
            await _firebaseSyncService.loadHistoryFromFirebase();
        userHistory.value = firebaseHistory;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final localHistory = prefs.getString(_localHistoryKey);
        if (localHistory != null) {
          final List<dynamic> decoded = json.decode(localHistory);
          userHistory.value = decoded
              .map((item) => Map<String, dynamic>.from({
                    ...Map<String, dynamic>.from(item),
                    'id': item['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'timestamp': DateTime.parse(item['timestamp'].toString()),
                  }))
              .toList();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToHistory(String hymnId, String title, String number) async {
    try {
      final user = _auth.currentUser;
      final historyEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'hymnId': hymnId,
        'title': title,
        'number': number,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (user != null) {
        await _firebaseSyncService.addHistoryToFirebase(hymnId, title, number);

        await loadUserHistory();
      } else {
        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> localHistory = [];

        final existingHistory = prefs.getString(_localHistoryKey);
        if (existingHistory != null) {
          final List<dynamic> decoded = json.decode(existingHistory);
          localHistory = decoded.cast<Map<String, dynamic>>().toList();
        }

        localHistory.insert(0, historyEntry);

        if (localHistory.length > 100) {
          localHistory = localHistory.sublist(0, 100);
        }

        await prefs.setString(_localHistoryKey, json.encode(localHistory));
      }

      await loadUserHistory();
    } catch (e) {}
  }

  Future<void> clearHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firebaseSyncService.clearHistoryFromFirebase();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_localHistoryKey);
      }

      userHistory.clear();

      final l10n = AppLocalizations.of(Get.context!)!;
      Get.snackbar(
        l10n.success,
        l10n.clearHistorySuccess,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(Get.context!)!;
      Get.snackbar(
        l10n.error,
        l10n.clearHistoryError,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
