import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/audio/presentation/widgets/album_art_card.dart';
import 'package:fihirana/features/audio/presentation/widgets/player_controls.dart';
import 'package:fihirana/features/audio/presentation/widgets/player_top_bar.dart';
import 'package:fihirana/features/audio/presentation/widgets/playlist_bottom_sheet.dart';
import 'package:fihirana/features/audio/presentation/widgets/progress_slider.dart';
import 'package:fihirana/features/audio/presentation/widgets/song_info_section.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_action_widgets.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_detail_skeleton.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_detail_widgets.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_improved_note_section_widget.dart';
import 'package:fihirana/l10n/app_localizations.dart';

Hymn hymn({
  String id = 'h1',
  String number = '12',
  int verseCount = 4,
  String? bridge = 'Alleluia, alleluia, sung by the whole assembly, '
      'line after line, until the last verse is done.',
  String? hint,
  String createdBy = '',
}) {
  return Hymn(
    id: id,
    hymnNumber: number,
    title: 'Ny fihirana lehibe',
    verses: [
      for (int i = 0; i < verseCount; i++)
        'Andalana ${i + 1}: ny tenin’ny fihirana dia lava kely mba hampisehoana '
            'ny fisarana ny lahatsoratra sy ny fandraharam-panorana.',
    ],
    bridge: bridge,
    hymnHint: hint,
    createdAt: DateTime(2026, 3, 4),
    createdBy: createdBy,
  );
}

void main() {
  ThemeData theme(Brightness brightness) => buildFihiranaTheme(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6FED),
          brightness: brightness,
        ),
      );

  Future<void> pump(WidgetTester tester, Widget child,
      {Brightness brightness = Brightness.light}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    expect(tester.takeException(), isNull);
  }

  for (final brightness in Brightness.values) {
    group('$brightness', () {
      testWidgets('the page scrolls and the chorus stays pinned',
          (tester) async {
        await pump(
          tester,
          HymnPageWidget(
            hymn: hymn(),
            fontSize: 16,
            countFontSize: 50,
            isUserAuthenticated: false,
            onNoteEdit: (_) {},
          ),
          brightness: brightness,
        );
        expect(find.text('1'), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        expect(tester.takeException(), isNull);
      });

      testWidgets('a page with no chorus, hint or author still lays out',
          (tester) async {
        await pump(
          tester,
          HymnPageWidget(
            hymn: hymn(bridge: null, verseCount: 1),
            fontSize: 16,
            countFontSize: 50,
            isUserAuthenticated: false,
            onNoteEdit: (_) {},
          ),
          brightness: brightness,
        );
        await pump(
          tester,
          HymnPageWidget(
            hymn: hymn(hint: 'Soraty amin’ny 1890.', createdBy: 'Rakoto'),
            fontSize: 16,
            countFontSize: 50,
            isUserAuthenticated: false,
            onNoteEdit: (_) {},
          ),
          brightness: brightness,
        );
      });

      testWidgets('the reader’s note section opens and closes',
          (tester) async {
        await pump(
          tester,
          const ImprovedNoteSectionProbe(),
          brightness: brightness,
        );
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('the player chrome lays out in every state',
          (tester) async {
        await pump(
          tester,
          Column(
            children: [
              const PlayerTopBar(),
              const Expanded(child: HymnPlate(hymnNumber: '12')),
              SongInfoSection(
                title: 'Ny fihirana lehibe',
                hymnNumber: '12',
                isFavorite: true,
                onToggleFavorite: () {},
              ),
              ProgressSlider(
                duration: const Duration(minutes: 3),
                position: const Duration(seconds: 40),
                isDragging: false,
                dragValue: 0,
                onChanged: (_) {},
                onChangeEnd: (_) {},
              ),
              PlayerControls(
                isPlaying: false,
                isLoading: true,
                autoPlayNext: true,
                onAutoPlayNextChange: (_) {},
                onPlayPrevious: () {},
                onTogglePlayPause: () {},
                onPlayNext: () {},
                onShowPlaylist: () {},
              ),
            ],
          ),
          brightness: brightness,
        );
      });

      testWidgets('the playlist sheet answers empty and full', (tester) async {
        await pump(
          tester,
          const PlaylistBottomSheet(playlist: null, currentHymn: null),
          brightness: brightness,
        );
        await pump(
          tester,
          PlaylistBottomSheet(
            playlist: [hymn(), hymn(id: 'h2', number: '13')],
            currentHymn: hymn(),
            onHymnChange: (_) {},
            onDownload: (_) {},
            isDownloaded: (h) => h.id == 'h2',
            getDownloadProgress: (h) => h.id == 'h2' ? 0.4 : null,
          ),
          brightness: brightness,
        );
        expect(find.text('13'), findsOneWidget);
      });

      testWidgets('the detail skeleton and the row actions lay out',
          (tester) async {
        await pump(
          tester,
          Column(
            children: [
              Expanded(
                child: ListView(
                  children: const [HymnDetailSkeleton()],
                ),
              ),
              FavoriteButtonWidget(
                isFavorite: true,
                onPressed: () {},
              ),
              AudioButtonWidget(
                hasAudio: true,
                isPlaying: true,
                hymnId: 'h1',
                onPressed: () {},
              ),
              FontSizeSliderWidget(fontSize: 18, onChanged: (_) {}),
            ],
          ),
          brightness: brightness,
        );
      });
    });
  }
}

/// The note section keeps its own controller; this pumps it with a saved note.
class ImprovedNoteSectionProbe extends StatelessWidget {
  const ImprovedNoteSectionProbe({super.key});

  @override
  Widget build(BuildContext context) {
    return ImprovedNoteSectionWidget(
      userNote: Note(
        id: 'n1',
        hymnId: 'h1',
        userId: 'u1',
        userEmail: 'a@b.cd',
        content: 'Ny andalana voalohany dia mampahatsiahy ahy ny fihainoako.',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        userName: 'Rakoto',
      ),
      onNoteEdit: (_) {},
      onAddNote: () {},
      fontSize: 16,
    );
  }
}
