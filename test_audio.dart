import 'package:http/http.dart' as http;

void main() async {
  // Test some hymn IDs
  final testIds = [
    '1',
    '1-NY-MIARA-DIA-AMINI-JESOSY-NO-TIAKO',
    '10',
    '10-DIOVY-AHO',
  ];

  for (final id in testIds) {
    final url = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$id.mp3';
    try {
      final response = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 5));
      print('$id: ${response.statusCode == 200 ? 'EXISTS' : 'NOT FOUND (${response.statusCode})'}');
    } catch (e) {
      print('$id: ERROR - $e');
    }
  }
}