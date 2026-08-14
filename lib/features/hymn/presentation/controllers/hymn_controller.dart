import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/usecases/search_hymns_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/add_to_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/remove_from_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/is_favorite_usecase.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/error/error_handler.dart';

class HymnController extends GetxController {
  late final TextEditingController searchController;

  final SearchHymnsUseCase _searchHymnsUseCase;
  final AddToFavoritesUseCase _addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase _removeFromFavoritesUseCase;
  final IsFavoriteUseCase _isFavoriteUseCase;

  // Keep reference to service for streams and methods not yet in use cases
  final _hymnService = HymnService();
  final favoriteStatuses = <String, String>{}.obs;
  StreamSubscription? _favoriteStatusSubscription;
  bool _isDisposed = false;

  // Optimized search and filtering
  final RxList<Hymn> _allHymns = <Hymn>[].obs;
  final RxList<Hymn> filteredHymns = <Hymn>[].obs;
  final RxBool isLoading = false.obs;
  Timer? _debounce;
  StreamSubscription? _hymnsSubscription;

  HymnController({
    required SearchHymnsUseCase searchHymnsUseCase,
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required IsFavoriteUseCase isFavoriteUseCase,
  })  : _searchHymnsUseCase = searchHymnsUseCase,
        _addToFavoritesUseCase = addToFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _isFavoriteUseCase = isFavoriteUseCase;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    _initFavoriteStatusStream();
    _initHymnsStream();

    // Setup debounce for search
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilter();
    });
  }

  void _initFavoriteStatusStream() {
    _favoriteStatusSubscription?.cancel();
    _favoriteStatusSubscription = _hymnService.getFavoriteStatusStream().listen(
      (statuses) {
        favoriteStatuses.value = Map<String, String>.from(statuses);
      },
      onError: (e) {
        debugPrint('Error in favorite status stream: $e');
      },
    );
  }

  Future<bool> createHymn(String hymnNumber, String title, List<String> verses,
      String? bridge, String? hymnHint) async {
    final l10n = AppLocalizations.of(Get.context!);
    Get.snackbar(
      l10n.noPermission,
      l10n.cannotAddHymns,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return false;
  }

  void _initHymnsStream() {
    isLoading.value = true;
    _hymnsSubscription = _hymnService.getLocalHymnsStream().listen((hymns) {
      final sortedHymns = List<Hymn>.of(hymns)
        ..sort((a, b) {
          final numberA = a.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
          final numberB = b.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
          if (numberA.isNotEmpty && numberB.isNotEmpty) {
            return int.parse(numberA).compareTo(int.parse(numberB));
          }
          return a.hymnNumber.compareTo(b.hymnNumber);
        });
      _allHymns.value = sortedHymns;
      _applyFilter();
      isLoading.value = false;
    });
  }

  void _applyFilter() {
    final searchQuery = searchController.text.toLowerCase();

    Iterable<Hymn> results = _allHymns;

    if (searchQuery.isNotEmpty) {
      results = results
          .where((hymn) =>
              hymn.hymnNumber.toLowerCase().contains(searchQuery) ||
              hymn.title.toLowerCase().contains(searchQuery) ||
              hymn.verses
                  .any((verse) => verse.toLowerCase().contains(searchQuery)))
          .toList(growable: false);
    }

    filteredHymns.value = results is List<Hymn>
        ? List<Hymn>.from(results, growable: false)
        : results.toList(growable: false);
  }

  Stream<Map<String, String>> getFavoriteStatusStream() {
    return _hymnService.getFavoriteStatusStream();
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    // Check if currently favorite and toggle accordingly
    final isCurrentlyFavorite = await _isFavoriteUseCase(hymn.id);
    if (isCurrentlyFavorite) {
      await _removeFromFavoritesUseCase(hymn.id);
    } else {
      await _addToFavoritesUseCase(hymn.id);
    }
  }

  Future<void> deleteHymn(Hymn hymn) async {
    await _hymnService.deleteHymn(hymn.id);
  }

  Stream<List<Hymn>> get hymnsStream => _hymnService.getLocalHymnsStream();

  Future<List<Hymn>> searchHymns(String query) async {
    return await _searchHymnsUseCase(query);
  }

  List<Hymn> filterHymnList(List<Hymn> hymns) {
    hymns.sort((a, b) {
      String numA = a.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
      String numB = b.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');

      if (numA.isNotEmpty && numB.isNotEmpty) {
        return int.parse(numA).compareTo(int.parse(numB));
      }

      return a.hymnNumber.compareTo(b.hymnNumber);
    });

    final searchQuery = searchController.text.toLowerCase();
    if (searchQuery.isEmpty) return hymns;

    return hymns
        .where((hymn) =>
            hymn.hymnNumber.toLowerCase().contains(searchQuery) ||
            hymn.title.toLowerCase().contains(searchQuery) ||
            hymn.verses
                .any((verse) => verse.toLowerCase().contains(searchQuery)))
        .toList();
  }

  String getPreviewText(Hymn hymn) {
    if (hymn.verses.isEmpty) return '';
    final firstVerse = hymn.verses[0];
    if (firstVerse.length > 50) {
      return '${firstVerse.substring(0, 50)}...';
    }
    return firstVerse;
  }

  // Safe getter for search controller
  TextEditingController get safeSearchController {
    if (_isDisposed) {
      return TextEditingController();
    }
    return searchController;
  }

  // Check if controller is disposed
  bool get isDisposed => _isDisposed;

  @override
  void onClose() {
    _isDisposed = true;
    _debounce?.cancel();
    _hymnsSubscription?.cancel();
    try {
      searchController.dispose();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
    _favoriteStatusSubscription?.cancel();
    super.onClose();
  }
}
