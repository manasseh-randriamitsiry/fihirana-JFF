import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/announcement/domain/repositories/i_announcement_service.dart';
import 'package:fihirana/features/daily_verse/domain/repositories/i_daily_verse_service.dart';

class BackgroundService extends GetxService {
  Timer? _announcementTimer;
  Timer? _dailyVerseRearmTimer;
  final IAnnouncementService _announcementService =
      Get.find<IAnnouncementService>();
  final IDailyVerseService _dailyVerseService = Get.find<IDailyVerseService>();

  @override
  void onInit() {
    super.onInit();

    _checkAnnouncements();

    _startAnnouncementChecks();
    _scheduleDailyVerseRearm();
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
    _dailyVerseRearmTimer = Timer(const Duration(seconds: 15), () async {
      try {
        await _dailyVerseService.rearmScheduledNotification();
      } catch (e) {
        if (kDebugMode) {
          print('Error re-arming the daily verse notification: $e');
        }
      }
    });
  }

  @override
  void onClose() {
    _announcementTimer?.cancel();
    _dailyVerseRearmTimer?.cancel();
    super.onClose();
  }
}
