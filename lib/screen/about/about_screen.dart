import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Contact from Hymns App&body=Hello,',
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Fiangonana',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Jesosy Famonjena Fahamarinantsika',
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
                const SizedBox(height: 5),
                Text(
                  'Antsororokavo Fianarantsoa 301',
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mpamorona rindrambaiko',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'Randriamitsiry Valimbavaka Nandrasana Manassé',
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 20),

                // Contact Buttons Section
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall('+261342943971'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call +261 34 29 439 71'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 45),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () =>
                      _sendEmail('manassehrandriamitsiry@gmail.com'),
                  icon: const Icon(Icons.email),
                  label: const Text('Send Email'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 45),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () =>
                      _launchURL('https://github.com/manasseh-randriamitsiry'),
                  icon: const Icon(Icons.code),
                  label: const Text('Visit GitHub'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 45),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall('*111*1*2*0342943971#'),
                  icon: const Icon(Icons.monetization_on),
                  label: const Text('Hanome fanohanana'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 45),
                    backgroundColor: Colors.green,
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Adiresy: Ambalavao tsienimparihy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'App version : 1.0.0',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
