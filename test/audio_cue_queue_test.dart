import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/presentation/widgets/audio_cue.dart';
import 'package:fihirana/features/audio/presentation/widgets/compact_audio_player_widget.dart';
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

  test('a finished hymn continues only into something it was given', () async {
    final service = AudioService.instance;
    await service.clearCue();
    service.setAutoPlayNext(false);
    service.currentPlayingHymnIdRx.value = '';

    // Nothing queued and no list asked to carry on, so the handover leaves the
    // player alone instead of starting a hymn nobody chose.
    expect(service.canContinue, isFalse);
    await service.continueAfterCurrent();
    expect(service.currentPlayingHymnId, isEmpty);

    await service.addToCue(_hymn('h13', '13'));
    expect(service.canContinue, isTrue);
    await service.clearCue();

    // Auto play needs the list the player was opened from, not just the switch.
    service.setAutoPlayNext(true);
    expect(service.canContinue, isFalse);
    service.setPlaylist([_hymn('h1', '1'), _hymn('h2', '2')], 0);
    expect(service.canContinue, isTrue);

    service.setAutoPlayNext(false);
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

  Future<void> pumpCueList(WidgetTester tester,
      {List<Widget> actions = const [], void Function(Hymn)? onPlayNow}) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED))),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AudioCueList(actions: actions, onPlayNow: onPlayNow),
      ),
    ));
    await tester.pump();
  }

  testWidgets('the cue holds nothing on screen until a hymn is added',
      (tester) async {
    final service = AudioService.instance;
    await service.clearCue();

    await pumpCueList(tester,
        actions: [const TextButton(onPressed: null, child: Text('Add'))]);

    expect(find.text('Next'), findsNothing);
    expect(find.text('Add'), findsNothing);

    // The host holds the block unconditionally, so it appears on its own.
    await service.addToCue(_hymn('h13', '13'));
    await tester.pump();

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Fihirana 13'), findsOneWidget);
  });

  testWidgets('tapping a cued hymn leaves the queue to the host',
      (tester) async {
    final service = AudioService.instance;
    await service.clearCue();
    await service.addToCue(_hymn('h13', '13'));
    await service.addToCue(_hymn('h1', '1'));

    Hymn? handedOver;
    await pumpCueList(tester, onPlayNow: (hymn) => handedOver = hymn);

    await tester.tap(find.text('Fihirana 13'));
    await tester.pump();

    expect(handedOver?.id, 'h13');
    expect(service.cue.map((h) => h.id), ['h1']);
  });

  testWidgets('the player keeps the queue on screen as hymns leave it',
      (tester) async {
    final service = AudioService.instance;
    await service.clearCue();
    // Nothing is loaded in the test harness, so the transport and the offer to
    // queue start from an empty player.
    service.currentPlayingHymnIdRx.value = '';
    await service.addToCue(_hymn('h13', '13'));
    await service.addToCue(_hymn('h1', '1'));

    await tester.pumpWidget(MaterialApp(
      theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED))),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CompactAudioPlayerWidget(hymn: _hymn('h20', '20')),
      ),
    ));
    await tester.pump();

    // Nothing is loaded in the test harness, so the offer to queue the hymn on
    // screen is absent - but the hymns still waiting have to be visible.
    expect(find.text('Add'), findsNothing);
    expect(find.text('Fihirana 13'), findsOneWidget);
    expect(find.text('Fihirana 1'), findsOneWidget);

    await service.clearCue();
    await tester.pump();

    expect(find.text('Next'), findsNothing);
  });

  testWidgets('a second hymn is asked about, and cueing confirms the tap',
      (tester) async {
    final service = AudioService.instance;
    await service.clearCue();

    await tester.pumpWidget(GetMaterialApp(
      theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED))),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => playOrCueHymn(context, _hymn('h13', '13')),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(service.cue.single.id, 'h13');
    // The confirmation carries the hymn the tap queued.
    expect(find.text('13 Fihirana 13'), findsOneWidget);

    // The floating confirmation dismisses itself, and its timer has to run out
    // before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('13 Fihirana 13'), findsNothing);
  });
}
