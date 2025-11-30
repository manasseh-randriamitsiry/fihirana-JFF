import 'package:shared_preferences/shared_preferences.dart';

class FontService {
  static const _fontKey = 'selected_font';

  static Future<String?> getSelectedFont() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontKey);
  }

  static Future<void> setSelectedFont(String font) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font);
  }
}
