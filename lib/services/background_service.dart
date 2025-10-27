import 'dart:async';
import 'package:get/get.dart';
import 'announcement_service.dart';

class BackgroundService extends GetxService {
  Timer? _announcementTimer;
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  void onInit() {
    super.onInit();
    // Check immediately when app starts
    _checkAnnouncements();
    // Then set up periodic checks
    _startAnnouncementChecks();
  }

  void _startAnnouncementChecks() {
    // Check every 5 minutes
    _announcementTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAnnouncements(),
    );
  }

  Future<void> _checkAnnouncements() async {
    await _announcementService.checkNewAnnouncements();
  }

  @override
  void onClose() {
    _announcementTimer?.cancel();
    super.onClose();
  }
} 