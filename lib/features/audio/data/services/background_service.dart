import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/announcement/domain/repositories/i_announcement_service.dart';

class BackgroundService extends GetxService with WidgetsBindingObserver {
  Timer? _announcementTimer;
  final IAnnouncementService _announcementService =
      Get.find<IAnnouncementService>();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startAnnouncementChecks();
    _checkAnnouncements();
  }

  void _startAnnouncementChecks() {
    _announcementTimer?.cancel();
    _announcementTimer = Timer.periodic(
      const Duration(hours: 2),
      (_) => _checkAnnouncements(),
    );
  }

  Future<void> _checkAnnouncements() async {
    await _announcementService.checkNewAnnouncements();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAnnouncementChecks();
      _checkAnnouncements();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _announcementTimer?.cancel();
      _announcementTimer = null;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _announcementTimer?.cancel();
    super.onClose();
  }
}
