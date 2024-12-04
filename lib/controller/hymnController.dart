import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/hymn.dart';
import '../services/hymn_service.dart';

class HymnController extends GetxController {
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  final HymnService _hymnService = HymnService();

  Future<bool> createHymn(String hymnNumber, String title, List<String> verses,
      String? bridge, String? hymnHint) async {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    Hymn newHymn = Hymn(
      id: '',
      title: title,
      verses: verses,
      bridge: bridge,
      hymnNumber: hymnNumber,
      hymnHint: hymnHint,
      createdAt: now,
      createdBy: user?.displayName ?? 'Unknown User',
      createdByEmail: user?.email,
    );

    bool result = await _hymnService.addHymn(newHymn);
    return result;
  }
}
