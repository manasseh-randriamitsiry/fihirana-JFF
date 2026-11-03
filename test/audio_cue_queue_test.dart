import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/presentation/widgets/playlist_bottom_sheet.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';

Hymn _hymn(String id, String number) => Hymn(
      id: id,
      hymnNumber: number,
      title: 'Fihirana $number',
      verses: const [],
      createdAt: DateTime(2026, 11, 3),
      createdBy: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The service builds an AudioPlayer eagerly, so the channels it reaches for
    // on startup have to answer instead of throwing MissingPluginException.
    for (final name in [
      'com.ryanheise.just_audio',
      'com.ryanheise.audio_session',
      'com.ryanheise.audioservice.AudioService',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
    }
  });

  test('a cue keeps duplicates and holds the order it was added in', () async {
    final service = AudioService.instance;
    await service.clearCue();

    await service.addToCue(_hymn('h1', '1'));
    await service.addToCue(_hymn('h13', '13'));
    await service.addToCue(_hymn('h1', '1'));

    expect(service.cue.map((h) => h.id), ['h1', 'h13', 'h1']);
    expect(service.hasCue, isTrue);
  });

  test('the cue survives a restart using only id, number and title', () async {
    final service = AudioService.instance;
    await service.clearCue();
    await service.addToCue(_hymn('h13', '13'));

    final prefs = await SharedPreferences.getInstance();
    final saved =
        (jsonDecode(prefs.getString('audio_cue_queue')!) as List).cast();
    expect(saved.single, {'id': 'h13', 'number': '13', 'title': 'Fihirana 13'});

    // A restart starts with an empty queue, so the reload has to rebuild the
    // hymns from prefs alone, without the corpus that is still loading.
    await service.clearCue();
    await prefs.setString(
        'audio_cue_queue',
        jsonEncode([
          {'id': 'h13', 'number': '13', 'title': 'Fihirana 13'}
        ]));
    await service.restoreCue();

    expect(service.cue.single.id, 'h13');
    expect(service.cue.single.hymnNumber, '13');
    expect(service.cue.single.title, 'Fihirana 13');
  });

  test('clearing empties the queue and what was saved for the next start',
      () async {
    final service = AudioService.instance;
    await service.addToCue(_hymn('h1', '1'));
    await service.clearCue();

    expect(service.cue, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('audio_cue_queue'), isNot(contains('h1')));
  });

  test('dropping or moving a cue entry that is not there changes nothing',
      () async {
    final service = AudioService.instance;
    await service.clearCue();
    await service.addToCue(_hymn('h1', '1'));
    await service.addToCue(_hymn('h2', '2'));

    await service.removeCuedAt(5);
    await service.moveCued(-1, 9);
    expect(service.cue.map((h) => h.id), ['h1', 'h2']);

    await service.moveCued(0, 1);
    expect(service.cue.map((h) => h.id), ['h2', 'h1']);

    await service.removeCuedAt(0);
    expect(service.cue.map((h) => h.id), ['h1']);
  });

  test('corrupt cue data is ignored instead of blocking the player', () async {
    final service = AudioService.instance;
    await service.clearCue();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_cue_queue', '{"not":"a list"}');
    await service.restoreCue();

    expect(service.cue, isEmpty);
  });

  testWidgets('the queue sheet shows what is cued and lets it be dropped',
      (tester) async {
    final service = AudioService.instance;
    await service.clearCue();
    await service.addToCue(_hymn('h13', '13'));

    await tester.pumpWidget(MaterialApp(
      theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED))),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PlaylistBottomSheet(
          playlist: [_hymn('h1', '1')],
          currentHymn: _hymn('h1', '1'),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Fihirana 13'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.cue, isEmpty);
    expect(find.text('Fihirana 13'), findsNothing);
  });
}
