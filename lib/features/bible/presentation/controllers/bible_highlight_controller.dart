import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';
import 'package:fihirana/features/bible/data/services/bible_highlight_service.dart';
import 'package:fihirana/core/error/error_handler.dart';

class BibleHighlightController extends GetxController {
  final BibleHighlightService _highlightService;

  BibleHighlightController({required BibleHighlightService highlightService})
      : _highlightService = highlightService;

  // Highlights
  final RxList<BibleHighlight> highlights = <BibleHighlight>[].obs;
  final RxList<BibleHighlight> publicHighlights = <BibleHighlight>[].obs;
  final RxList<BibleHighlight> allUserHighlights = <BibleHighlight>[].obs;

  // Highlighted verse for UI feedback
  var highlightedVerse = Rx<BibleHighlight?>(null);

  void loadHighlights(String bookName, int chapter) {
    _loadUserHighlights(bookName, chapter);
    _loadPublicHighlights(bookName, chapter);
  }

  void loadAllUserHighlights() {
    try {
      _highlightService.getAllUserHighlightsStream().listen(
        (userHighlights) {
          allUserHighlights.value = userHighlights;
        },
        onError: (error) {
          ErrorHandler.handleError(error, message: 'errorLoadingHighlights'.tr);
        },
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingHighlights'.tr);
    }
  }

  void _loadUserHighlights(String bookName, int chapter) {
    try {
      _highlightService.getHighlightsStream(bookName, chapter).listen(
        (userHighlights) {
          highlights.value = userHighlights;
        },
        onError: (error) {
          ErrorHandler.handleError(error, message: 'errorLoadingHighlights'.tr);
        },
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingHighlights'.tr);
    }
  }

  void _loadPublicHighlights(String bookName, int chapter) {
    try {
      _highlightService.getPublicHighlightsStream(bookName, chapter).listen(
        (pubHighlights) {
          publicHighlights.value = pubHighlights;
        },
        onError: (error) {
          ErrorHandler.handleError(error,
              message: 'errorLoadingPublicHighlights'.tr);
        },
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingPublicHighlights'.tr);
    }
  }

  Future<void> addHighlight(
      String bookName, int chapter, int verse, String color) async {
    try {
      final highlight = BibleHighlight(
        id: '',
        bookName: bookName,
        chapter: chapter,
        startVerse: verse,
        endVerse: verse,
        userId: '',
        userName: '',
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _highlightService.saveHighlight(highlight);
      if (success) {
        highlightedVerse.value = highlight;
        // Auto-clear highlight feedback after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          highlightedVerse.value = null;
        });
      } else {
        ErrorHandler.handleError('Failed to save highlight',
            message: 'errorSavingHighlight'.tr);
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSavingHighlight'.tr);
    }
  }

  Future<void> removeHighlight(String highlightId) async {
    try {
      final success = await _highlightService.deleteHighlight(highlightId);
      if (!success) {
        ErrorHandler.handleError('Failed to delete highlight',
            message: 'errorDeletingHighlight'.tr);
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorDeletingHighlight'.tr);
    }
  }

  Future<void> updateHighlight(BibleHighlight highlight) async {
    try {
      final success = await _highlightService.updateHighlight(highlight);
      if (!success) {
        ErrorHandler.handleError('Failed to update highlight',
            message: 'errorUpdatingHighlight'.tr);
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorUpdatingHighlight'.tr);
    }
  }

  Future<bool> canEditHighlight(BibleHighlight highlight) async {
    try {
      return await _highlightService.canEditHighlight(highlight);
    } catch (e) {
      ErrorHandler.handleError(e,
          message: 'errorCheckingHighlightPermission'.tr);
      return false;
    }
  }

  BibleHighlight? getHighlightForVerse(int verseNumber) {
    return highlights.firstWhereOrNull((h) => h.containsVerse(verseNumber)) ??
        publicHighlights.firstWhereOrNull((h) => h.containsVerse(verseNumber));
  }

  void clearHighlights() {
    highlights.clear();
    publicHighlights.clear();
    highlightedVerse.value = null;
  }

  bool isVerseHighlighted(int verse) => getHighlightForVerse(verse) != null;
}
