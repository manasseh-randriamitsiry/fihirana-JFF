import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';
import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/presentation/widgets/announcement_widgets.dart';
import 'package:fihirana/features/audio/presentation/widgets/album_art_card.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_reader_widgets.dart';
import 'package:fihirana/features/audio/presentation/widgets/compact_audio_player_widget.dart';
import 'package:fihirana/features/audio/presentation/widgets/modern_audio_player_widget.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_detail_widgets.dart';
import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/features/playlist/presentation/widgets/playlist_detail_widgets.dart';
import 'package:fihirana/features/playlist/presentation/widgets/playlist_item_card.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

/// The visual record of the redesign: the six frames the system is judged on,
/// rendered by the real Skia pipeline at a phone size.
///
/// `flutter test --update-goldens test/design_goldens_test.dart` regenerates
/// them; a diff in the goldens is a design change, not noise.
void main() {
  const Size phone = Size(390, 844);

  // flutter_test replaces every family with a placeholder box unless the real
  // faces are loaded, which would make these frames useless to look at.
  setUpAll(() async {
    const families = {
      'Montserrat': ['Montserrat-Regular', 'Montserrat-Bold', 'Montserrat-Italic'],
      'Lato': ['Lato-Regular', 'Lato-Bold'],
      'Hack': ['Hack-Regular', 'Hack-Bold'],
    };
    for (final entry in families.entries) {
      final loader = FontLoader(entry.key);
      for (final face in entry.value) {
        try {
          final data = await rootBundle.load('assets/fonts/$face.ttf');
          loader.addFont(Future.value(data));
        } catch (_) {
          // Only the faces pubspec declares are bundled; the rest fall back.
        }
      }
      await loader.load();
    }
  });

  // Asset I/O cannot await inside a testWidgets fake-async zone, so the chapter
  // is read once, here, and the frames only lay it out.
  var bibleBook = '';
  var bibleChapter = <int, String>{};
  setUpAll(() async {
    final service = BibleService();
    await service.initialize();
    for (final book in service.getAllBooks()) {
      final chapter = book.getChapter(1);
      if (chapter != null && chapter.verses.length > 6) {
        bibleBook = book.name;
        bibleChapter = chapter.verses;
        break;
      }
    }
  });

  Hymn hymn({int verses = 4, String? bridge, String? hint}) => Hymn(
        id: 'h1',
        hymnNumber: '128',
        title: 'Endaovao izay nofo sy ratra',
        verses: [for (var i = 0; i < verses; i++) 'Andalana $i. Fihirana ho an’ny Tompo, hira fiderana amin’ny Ray Sy Ny Fanahy Masina. '],
        bridge: bridge,
        hymnHint: hint,
        createdAt: DateTime(2026, 3, 4),
        createdBy: 'Fanjanahary R',
      );

  Future<void> frame(WidgetTester tester, String name, Widget child) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  group('goldens', () {
    testWidgets('the register', (tester) async {
      await frame(tester, 'register', Scaffold(
        appBar: AppBar(title: const Text('Fihirana')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppScale.space12),
              child: AppSearchField(
                controller: TextEditingController(text: 'fanahy'),
                hintText: 'Karhou ny fihirana',
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: 9,
                separatorBuilder: (_, __) => const AppRule(),
                itemBuilder: (context, i) => AppRegisterRow(
                  figure: '${(i + 3) * 12}',
                  title: i == 3
                      ? 'Endaovao izay nofo sy ratra'
                      : 'Fiderana amin’ny Ray Sy Ny Fanahy Masina',
                  subtitle: 'Aoki 12 • Fihirana ho an’ny Tompo',
                  selected: i == 3,
                  trailing: const Icon(Icons.favorite_rounded,
                      size: AppScale.iconMd, color: Color(0xFF2F6FED)),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ));
    });

    testWidgets('a hymn page', (tester) async {
      await frame(tester, 'hymn_page', HymnPageWidget(
        hymn: hymn(
          bridge: 'Raisoao ry Aoka ho azy Isika',
          hint: 'Salamo 95 : 1-7',
        ),
        fontSize: 18,
        countFontSize: 22,
        isUserAuthenticated: false,
        onNoteEdit: (_) {},
      ));
    });

    testWidgets('the full player', (tester) async {
      await frame(tester, 'player', Scaffold(
        body: ModernAudioPlayerWidget(hymn: hymn()),
      ));
    });

    testWidgets('the compact player', (tester) async {
      await frame(tester, 'compact_player', Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: CompactAudioPlayerWidget(hymn: hymn()),
        ),
      ));
    });

    testWidgets('a hymn page with a note', (tester) async {
      await frame(tester, 'hymn_note', HymnPageWidget(
        hymn: hymn(verses: 2, hint: 'Salamo 95'),
        fontSize: 18,
        countFontSize: 22,
        isUserAuthenticated: true,
        userNote: null,
        onNoteEdit: (_) {},
      ));
    });

    testWidgets('the four states', (tester) async {
      await frame(tester, 'state_empty', AppStateView(
        state: AppState.empty,
        emptyTitle: 'Tsy mbola misy fihirana',
        emptyMessage: 'Manampy fihirana ho ana tiavina ianao.',
        emptyIcon: Icons.favorite_border_rounded,
        emptyAction: FilledButton(
            onPressed: () {}, child: const Text('Manomboka')),
        child: const SizedBox.shrink(),
      ));
      await frame(tester, 'state_error', AppStateView(
        state: AppState.error,
        emptyTitle: '',
        errorTitle: 'Tsy afaka nanjary ny hira',
        errorMessage: 'Jereo ny fifandraisana dia andramo indray.',
        onRetry: () {},
        child: const SizedBox.shrink(),
      ));
      await frame(tester, 'state_loading', const AppStateView(
        state: AppState.loading,
        emptyTitle: '',
        child: SizedBox.shrink(),
      ));
    });

    testWidgets('a grouped settings surface', (tester) async {
      await frame(tester, 'settings_group', Scaffold(
        appBar: AppBar(title: const Text('Fandrindrana')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppScale.space16),
          children: const [
            AppSection(
              title: 'Sangy',
              child: AppGroupedSurface(
                children: [
                  AppListRow(
                      icon: Icons.palette_outlined, title: 'Loko', subtitle: 'Alimana'),
                  AppGroupDivider(),
                  AppListRow(
                      icon: Icons.text_fields_outlined,
                      title: 'Haben-tsoratra',
                      subtitle: '18'),
                ],
              ),
            ),
            AppSection(
              title: 'Fivarotana',
              child: AppGroupedSurface(
                children: [
                  AppListRow(
                      icon: Icons.notifications_outlined,
                      title: 'Fampandrenesana'),
                  AppGroupDivider(),
                  AppListRow(
                    icon: Icons.logout_rounded,
                    title: 'Miala',
                    destructive: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppScale.space16),
              child: HymnPlate(hymnNumber: '128'),
            ),
          ],
        ),
      ));
    });

    testWidgets('a bible chapter', (tester) async {
      expect(bibleChapter, isNotEmpty,
          reason: 'the bible asset should load in a test');
      final numbers = bibleChapter.keys.toList()..sort();

      await frame(tester, 'bible_reader', Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$bibleBook 1'),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(AppScale.ruleHair),
              child: AppRule(firm: true),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppScale.gutter, AppScale.space16, AppScale.gutter,
                AppScale.space40),
            children: [
              for (final n in numbers)
                BibleVerseItemWidget(
                  verseNumber: n,
                  verseText: bibleChapter[n] ?? '',
                  verseStyle: AppTypography.lyricText(context, size: 18),
                  fontSize: 18,
                  highlightedVerse: numbers.length > 4 ? numbers[4] : 0,
                  isSelected: n == numbers.first,
                  isHighlighted: n == (numbers.length > 2 ? numbers[2] : -1),
                  isSearchHighlighted:
                      n == (numbers.length > 3 ? numbers[3] : -1),
                  onTap: () {},
                ),
            ],
          ),
        ),
      ));
    });

    testWidgets('the chapter grid', (tester) async {
      await frame(tester, 'bible_chapters', Scaffold(
        appBar: AppBar(title: const Text('Josoa')),
        body: BibleChapterGridWidget(
          chapters: [for (var i = 1; i <= 24; i++) i],
          onChapterSelected: (_) {},
        ),
      ));
    });

    testWidgets('typography and the drawer row', (tester) async {
      await frame(tester, 'rows', Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppGroupHead(title: 'Fihirana', count: 614),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppScale.gutter),
                child: Column(
                  children: [
                    AppRegisterRow(
                      title: 'Endaovao izay nofo sy ratra',
                      subtitle: 'Voafarana 2026-03-04',
                      figure: '128',
                      selected: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: AppScale.buttonGap),
                    AppRegisterRow(
                      title: 'Fiderana amin’ny Ray',
                      leadingWidget: const Icon(Icons.note_rounded,
                          size: AppScale.iconLg),
                      onTap: () {},
                      trailing: const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppScale.buttonGap),
                    AppRegisterRow(
                      title: 'Miala',
                      leadingWidget:
                          const Icon(Icons.logout_rounded,
                              size: AppScale.iconLg),
                      destructive: true,
                      onTap: () {},
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppScale.gutter, vertical: AppScale.space16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Fiderana'),
                    ),
                    const SizedBox(width: AppScale.buttonGap),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Meny'),
                    ),
                    const SizedBox(width: AppScale.buttonGap),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppScale.space16),
                child: Builder(
                  builder: (context) => Text(
                    'Fihirana ho an’ny Tompo',
                    style: AppTypography.lyricText(context, size: 21),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    });

    testWidgets('the content cards', (tester) async {
      await frame(tester, 'cards', Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppScale.gutter),
            children: [
              const AppGroupHead(title: 'Annonces', count: 2),
              const SizedBox(height: AppScale.buttonGap),
              AnnouncementCardWidget(
                announcement: Announcement(
                  id: 'a1',
                  title: 'Fiderana ho an’ny Tompo',
                  message:
                      'Misaotra anareo rehetra teza nankoa amin’ny fivoriana. '
                      'Ny taratasy fanambaran’ny fihaonana dia azo jerena ao '
                      'amin’ny fandrindrana.',
                  createdAt: DateTime(2026, 10, 24, 9, 30),
                  expiresAt: DateTime(2026, 11, 20),
                  createdBy: 'Fanjanahary R',
                  createdByEmail: 'fihirana@example.mg',
                ),
                isAdmin: true,
              ),
              const SizedBox(height: AppScale.buttonGap),
              PlaylistItemCard(
                playlist: Playlist(
                  id: 'p1',
                  title: 'Fihirana fivoriana',
                  date: DateTime(2026, 10, 12),
                  hymnIds: const ['128', '129', '130'],
                  createdBy: 'Fanjanahary R',
                  createdAt: DateTime(2026, 10, 12),
                  updatedAt: DateTime(2026, 10, 12),
                ),
                onTap: () {},
                onShare: () {},
                onDelete: () {},
              ),
              const SizedBox(height: AppScale.buttonGap),
              PlaylistHymnItem(
                hymn: hymn(),
                index: 0,
                onTap: () {},
                onRemove: () {},
              ),
              const SizedBox(height: AppScale.space24),
            ],
          ),
        ),
      ));
    });

    testWidgets('the settings rhythm', (tester) async {
      await frame(tester, 'settings_pages', Scaffold(
        appBar: AppBar(title: const Text('Fandrindrana')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: AppScale.space24),
          children: [
            AppSection(
              title: 'Application',
              child: AppGroupedSurface(
                padding: const EdgeInsets.all(AppScale.gutter),
                children: [
                  Builder(builder: (context) => Icon(Icons.music_note_rounded,
                      size: AppScale.tile,
                      color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: AppScale.space12),
                  const Text(
                    'Fihirana — Boky fihirana',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppScale.space4),
                  const Text('Sokajiny 1.0.55', textAlign: TextAlign.center),
                  const SizedBox(height: AppScale.space8),
                  const Text('Ambalavao, Madagasikara',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const AppSection(
              title: 'Sangy',
              child: AppGroupedSurface(
                children: [
                  AppListRow(
                      icon: Icons.palette_outlined, title: 'Loko',
                      subtitle: 'Alimana'),
                  AppGroupDivider(),
                  AppListRow(icon: Icons.language_rounded, title: 'Fiteny'),
                  AppGroupDivider(),
                  AppListRow(
                      icon: Icons.dark_mode_outlined,
                      title: 'Maizina',
                      trailing: Switch(value: true, onChanged: null)),
                ],
              ),
            ),
            const AppSection(
              title: 'Fifandraisana',
              child: AppGroupedSurface(
                children: [
                  AppListRow(icon: Icons.phone_rounded, title: 'Tarovana'),
                  AppGroupDivider(),
                  AppListRow(icon: Icons.email_rounded, title: 'Addresy'),
                  AppGroupDivider(),
                  AppListRow(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Fanampiana',
                      subtitle: 'Mankasitraka ny fanamboarana an\'i Fihirana'),
                ],
              ),
            ),
          ],
        ),
      ));
    });
  });
}
