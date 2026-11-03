import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/announcement/domain/repositories/i_announcement_service.dart';
import 'package:fihirana/features/daily_verse/domain/repositories/i_daily_verse_service.dart';

class BackgroundService extends GetxService with WidgetsBindingObserver {
  Timer? _announcementTimer;
  Timer? _dailyVerseRearmTimer;
  final IAnnouncementService _announcementService =
      Get.find<IAnnouncementService>();
  final IDailyVerseService _dailyVerseService = Get.find<IDailyVerseService>();

  /// A swipe-away from Recents is a force-stop, and force-stop cancels every
  /// pending intent on Android 15 and up. Re-arming on the way back in restores
  /// the verse without waiting for the next cold start; the gap keeps a resume
  /// storm from thrashing the alarm scheduler.
  static const Duration _minRearmGap = Duration(minutes: 30);
  DateTime? _lastRearmAt;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    _checkAnnouncements();

    _startAnnouncementChecks();
    _scheduleDailyVerseRearm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastRearmAt;
    if (last != null && DateTime.now().difference(last) < _minRearmGap) return;
    unawaited(_rearmDailyVerse());
  }

  void _startAnnouncementChecks() {
    _announcementTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAnnouncements(),
    );
  }

  Future<void> _checkAnnouncements() async {
    await _announcementService.checkNewAnnouncements();
  }

  /// Deferred because resolving today's verse needs the Bible corpus, which
  /// startup deliberately keeps off the critical path.
  void _scheduleDailyVerseRearm() {
    _dailyVerseRearmTimer =
        Timer(const Duration(seconds: 15), () => _rearmDailyVerse());
  }

  Future<void> _rearmDailyVerse() async {
    _lastRearmAt = DateTime.now();
    try {
      await _dailyVerseService.rearmScheduledNotification();
    } catch (e) {
      if (kDebugMode) {
        print('Error re-arming the daily verse notification: $e');
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _announcementTimer?.cancel();
    _dailyVerseRearmTimer?.cancel();
    super.onClose();
  }
}
