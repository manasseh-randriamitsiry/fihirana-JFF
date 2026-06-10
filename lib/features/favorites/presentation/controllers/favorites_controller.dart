import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/favorites/domain/usecases/get_favorite_hymns_stream_usecase.dart';
import 'package:fihirana/features/favorites/domain/usecases/toggle_favorite_usecase.dart';
import 'package:fihirana/features/favorites/domain/usecases/check_audio_availability_usecase.dart';
import 'package:fihirana/features/favorites/domain/usecases/is_hymn_playing_usecase.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Favorites controller for managing favorite hymns
class FavoritesController extends GetxController {
  final GetFavoriteHymnsStreamUseCase _getFavoriteHymnsStreamUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final CheckAudioAvailabilityUseCase _checkAudioAvailabilityUseCase;
  final IsHymnPlayingUseCase _isHymnPlayingUseCase;

  FavoritesController({
    required GetFavoriteHymnsStreamUseCase getFavoriteHymnsStreamUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
    required CheckAudioAvailabilityUseCase checkAudioAvailabilityUseCase,
    required IsHymnPlayingUseCase isHymnPlayingUseCase,
  })  : _getFavoriteHymnsStreamUseCase = getFavoriteHymnsStreamUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        _checkAudioAvailabilityUseCase = checkAudioAvailabilityUseCase,
        _isHymnPlayingUseCase = isHymnPlayingUseCase;

  // Observable state
  final RxList<Hymn> favoriteHymns = <Hymn>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<Hymn> filteredHymns = <Hymn>[].obs;
  final RxMap<String, bool> audioAvailability = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
  }

  /// Setup streams
  void _setupStreams() {
    _getFavoriteHymnsStreamUseCase().listen(
      (hymnList) {
        favoriteHymns.assignAll(hymnList);
        _applySearchFilter();
        if (kDebugMode) {
          print('❤️ Favorite hymns updated: ${hymnList.length} total');
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to stream favorite hymns: $error';
        if (kDebugMode) {
          print('❌ Error streaming favorite hymns: $error');
        }
      },
    );
  }

  /// Search hymns
  void searchHymns(String query) {
    searchQuery.value = query;
    _applySearchFilter();
  }

  /// Apply search filter
  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredHymns.assignAll(favoriteHymns);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredHymns.assignAll(
        favoriteHymns
            .where((hymn) =>
                hymn.title.toLowerCase().contains(query) ||
                hymn.hymnNumber.toLowerCase().contains(query))
            .toList(),
      );
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(Hymn hymn) async {
    try {
      await _toggleFavoriteUseCase(hymn);
      if (kDebugMode) {
        print('✅ Favorite toggled for hymn: ${hymn.title}');
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorUpdatingFavorites'.tr);
    }
  }

  /// Check audio availability
  Future<void> checkAudioAvailability(String hymnId) async {
    if (!audioAvailability.containsKey(hymnId)) {
      try {
        final hasAudio = await _checkAudioAvailabilityUseCase(hymnId);
        audioAvailability[hymnId] = hasAudio;
      } catch (e) {
        ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
        audioAvailability[hymnId] = false;
      }
    }
  }

  /// Check if hymn is playing
  bool isHymnPlaying(String hymnId) {
    return _isHymnPlayingUseCase(hymnId);
  }

  /// Clear error
  void clearError() {
    errorMessage.value = '';
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    _setupStreams();
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}
