import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';

abstract class IBibleHighlightService {
  Stream<List<BibleHighlight>> getHighlightsStream(String bookName, int chapter);
  Stream<List<BibleHighlight>> getPublicHighlightsStream(String bookName, int chapter);
  Stream<List<BibleHighlight>> getAllUserHighlightsStream();
  Future<bool> saveHighlight(BibleHighlight highlight);
  Future<bool> updateHighlight(BibleHighlight highlight);
  Future<bool> deleteHighlight(String highlightId);
  Future<bool> canEditHighlight(BibleHighlight highlight);
}