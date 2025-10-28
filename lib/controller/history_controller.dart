import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/firebase_sync_service.dart'; // Add Firebase sync service

class HistoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService(); // Add Firebase sync service
  
  // Observable list of user's hymn history
  final RxList<Map<String, dynamic>> userHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSelectionMode = false.obs;
  final RxList<String> selectedItems = <String>[].obs;

  static const String _localHistoryKey = 'local_hymn_history';

  @override
  void onInit() {
    super.onInit();
    loadUserHistory();
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      loadUserHistory(); // Reload history when auth state changes
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
        // Delete from Firestore
        final batch = _firestore.batch();
        for (String id in selectedItems) {
          final docRef = _firestore
              .collection('users') // Changed from 'user_history' to 'users'
              .doc(user.uid)
              .collection('history')
              .doc(id);
          batch.delete(docRef);
        }
        await batch.commit();
      } else {
        // Delete from local storage
        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> localHistory = [];
        String? historyJson = prefs.getString(_localHistoryKey);
        if (historyJson != null) {
          localHistory = List<Map<String, dynamic>>.from(
              jsonDecode(historyJson).map((x) => Map<String, dynamic>.from(x)));
          localHistory.removeWhere((item) => selectedItems.contains(item['id']));
          await prefs.setString(_localHistoryKey, jsonEncode(localHistory));
        }
      }

      // Update the UI
      userHistory.removeWhere((item) => selectedItems.contains(item['id']));
      selectedItems.clear();
      isSelectionMode.value = false;

      Get.snackbar(
        'Vita!',
        'Voafafa ny tantara voafidy',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Nisy olana',
        'Tsy afaka mamafa ny tantara: $e',
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
        // Load from Firebase
        final firebaseHistory = await _firebaseSyncService.loadHistoryFromFirebase();
        userHistory.value = firebaseHistory;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final localHistory = prefs.getString(_localHistoryKey);
        if (localHistory != null) {
          final List<dynamic> decoded = json.decode(localHistory);
          userHistory.value = decoded.map((item) => Map<String, dynamic>.from({
            ...Map<String, dynamic>.from(item),
            'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), // Ensure ID exists
            'timestamp': DateTime.parse(item['timestamp'].toString()),
          })).toList();
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
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Add unique ID for local storage
        'hymnId': hymnId,
        'title': title,
        'number': number,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (user != null) {
        // Save to Firebase
        await _firebaseSyncService.addHistoryToFirebase(hymnId, title, number);
        // Reload history to reflect changes
        await loadUserHistory();
      } else {
        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> localHistory = [];
        
        final existingHistory = prefs.getString(_localHistoryKey);
        if (existingHistory != null) {
          final List<dynamic> decoded = json.decode(existingHistory);
          localHistory = decoded.cast<Map<String, dynamic>>().toList();
        }

        // Add new entry at the beginning
        localHistory.insert(0, historyEntry);
        
        // Keep only last 100 entries to prevent excessive storage use
        if (localHistory.length > 100) {
          localHistory = localHistory.sublist(0, 100);
        }

        await prefs.setString(_localHistoryKey, json.encode(localHistory));
      }
      
      await loadUserHistory(); // Reload history after adding new entry
    } catch (e) {
    }
  }

  Future<void> clearHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Clear Firestore history for authenticated users
        await _firebaseSyncService.clearHistoryFromFirebase();
      } else {
        // Clear local storage history for unauthenticated users
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_localHistoryKey);
      }
      
      userHistory.clear();
      
      Get.snackbar(
        'Vita!',
        'Voafafa ny tantara',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Nisy olana',
        'Tsy afaka mamafa ny tantara: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}