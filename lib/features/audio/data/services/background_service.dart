import 'dart:async';
import 'package:get/get.dart';
import 'package:fihirana/features/announcement/domain/repositories/i_announcement_service.dart';

class BackgroundService extends GetxService {
  Timer? _announcementTimer;
  final IAnnouncementService _announcementService =
      Get.find<IAnnouncementService>();

  @override
  void onInit() {
    super.onInit();

    _checkAnnouncements();

    _startAnnouncementChecks();
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

  @override
  void onClose() {
    _announcementTimer?.cancel();
    super.onClose();
  }
}
