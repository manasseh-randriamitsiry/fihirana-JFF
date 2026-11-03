import 'package:fihirana/features/bible/domain/entities/bible.dart';
import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';

/// A hand-written corpus, because the search rules can only be shown with a word
/// that appears in more than one book and chapter, and with a verse text the
/// corpus really does repeat elsewhere.
class FakeBibleService implements IBibleService {
  final List<BibleBook> books = [
    BibleBook(
      name: 'Salamo',
      abbreviation: 'SAL',
      chapters: 2,
      chapterData: {
        1: BibleChapter(number: 1, verses: {
          1: "Bindaao an'i Tompo amin'ny herin'ny fanahy",
          2: 'Tompo maalma',
        }),
        2: BibleChapter(number: 2, verses: {
          1: "Bindaao an'i Tompo",
          3: 'Tompo maalma',
        }),
      },
    ),
    BibleBook(
      name: 'Josoa',
      abbreviation: 'JOS',
      chapters: 1,
      chapterData: {
        1: BibleChapter(number: 1, verses: {
          1: "Ny asan'i Josoa",
          2: 'Josoa tompo maalma',
        }),
      },
    ),
  ];

  int searchVersesCalls = 0;

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize([Function(String)? loadingCallback]) async {}

  @override
  List<BibleBook> getAllBooks() => books;

  @override
  BibleBook? getBook(String bookName) =>
      books.where((book) => book.name == bookName).firstOrNull;

  @override
  BibleChapter? getChapter(String bookName, int chapterNumber) =>
      getBook(bookName)?.getChapter(chapterNumber);

  @override
  List<VerseSearchResult> searchVerses(String query) {
    searchVersesCalls++;
    final needle = query.toLowerCase();
    final results = <VerseSearchResult>[];
    for (final book in books) {
      for (final chapter in book.chapterData.values) {
        for (final entry in chapter.verses.entries) {
          if (entry.value.toLowerCase().contains(needle)) {
            results.add(VerseSearchResult(
              bookName: book.name,
              chapter: chapter.number,
              verse: entry.key,
              text: entry.value,
            ));
          }
        }
      }
    }
    return results;
  }

  @override
  List<BibleBook> searchBooks(String query) => books
      .where((book) => book.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
