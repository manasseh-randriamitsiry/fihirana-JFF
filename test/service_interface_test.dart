import 'package:flutter_test/flutter_test.dart';
import 'package:fihirana/services/interfaces/irecording_service.dart';
import 'package:fihirana/services/interfaces/ibible_service.dart';
import 'package:fihirana/services/mocks/mock_recording_service.dart';
import 'package:fihirana/services/mocks/mock_bible_service.dart';

/// Example test file showing how to use service interfaces for dependency injection
void main() {
  group('Service Interface Tests', () {
    late IRecordingService recordingService;
    late IBibleService bibleService;

    setUp(() {
      // Use mock implementations for testing
      recordingService = MockRecordingService();
      bibleService = MockBibleService();
    });

    test('RecordingService interface - start and stop recording', () async {
      // Arrange
      expect(recordingService.isRecording, false);
      expect(recordingService.recordings, isEmpty);

      // Act
      await recordingService.startRecording();
      expect(recordingService.isRecording, true);

      final recording = await recordingService.stopRecording();

      // Assert
      expect(recordingService.isRecording, false);
      expect(recordingService.recordings, hasLength(1));
      expect(recording, isNotNull);
      expect(recording!.id, isNotEmpty);
    });

    test('RecordingService interface - search recordings', () async {
      // Arrange
      await recordingService.startRecording();
      await recordingService.stopRecording();

      // Act
      final results = recordingService.searchRecordings('Mock');

      // Assert
      expect(results, hasLength(1));
      expect(results.first.title, contains('Mock'));
    });

    test('BibleService interface - initialize and get books', () async {
      // Arrange & Act
      await bibleService.initialize();
      final books = bibleService.getAllBooks();

      // Assert
      expect(bibleService.isInitialized, true);
      expect(books, isNotEmpty);
      expect(books.any((book) => book.name == 'Genesis'), true);
    });

    test('BibleService interface - search verses', () async {
      // Arrange
      await bibleService.initialize();

      // Act
      final results = bibleService.searchVerses('beginning');

      // Assert
      expect(results, isNotEmpty);
      expect(results.any((verse) => verse.text.contains('beginning')), true);
    });

    test('BibleService interface - get specific verse', () async {
      // Arrange
      await bibleService.initialize();

      // Act
      final verse = bibleService.getVerse('Genesis', 1, 1);

      // Assert
      expect(verse, isNotNull);
      expect(verse, contains('beginning'));
    });

    test('Service interface dependency injection example', () async {
      // This test shows how you can inject different implementations
      // of the same interface for different scenarios

      // Test with mock service
      IRecordingService testService = MockRecordingService();
      await testService.startRecording();
      final mockRecording = await testService.stopRecording();
      expect(mockRecording, isNotNull);

      // In real app, you would inject the real service:
      // IRecordingService productionService = Get.find<IRecordingService>();
      // await productionService.startRecording();
      // final realRecording = await productionService.stopRecording();
    });
  });

  group('Service Integration Tests', () {
    test('Multiple services working together', () async {
      // This test shows how multiple services can work together
      // through their interfaces

      final recordingService = MockRecordingService();
      final bibleService = MockBibleService();

      // Initialize both services
      await recordingService.initialize();
      await bibleService.initialize();

      // Create a recording with a Bible verse reference
      await recordingService.startRecording();
      final recording = await recordingService.stopRecording();

      // Get a Bible verse to associate with the recording
      final verse = bibleService.getRandomVerse();

      expect(recording, isNotNull);
      expect(verse, isNotNull);

      // In a real scenario, you might save the recording with the verse reference
      // through the service interfaces
    });
  });
}