import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fihirana/services/version_check_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '1.0.0';
  bool _checkingForUpdates = false;
  bool _updateAvailable = false;
  bool _flexibleUpdateDownloaded = false;

  @override
  void initState() {
    super.initState();
    _getAppVersion();

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });

    VersionCheckService.setOnFlexibleUpdateDownloadedCallback(() {
      if (mounted) {
        setState(() {
          _flexibleUpdateDownloaded = true;
        });
      }
    });
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

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

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {

      final updateAvailable = await VersionCheckService.checkForUpdateManually();

      if (mounted) {
        setState(() {
          _updateAvailable = updateAvailable;
          _checkingForUpdates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tsy afaka vaovao'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadAndInstallUpdate() async {
    try {

      if (VersionCheckService.isFlexibleUpdateAvailable()) {

        await VersionCheckService.completeFlexibleUpdate();
      } else {

        setState(() {
          _checkingForUpdates = true;
        });

        await VersionCheckService.triggerFlexibleUpdate();

        if (mounted) {
          setState(() {
            _checkingForUpdates = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nisy olana'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      await VersionCheckService.triggerImmediateUpdate();
    } catch (e) {

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nisy olana fa avereno rehefa afaka kelikely'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text('?', style: TextStyle(color: textColor)),
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
                  'Mpamorona',
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
                  label: const Text('GitHub'),
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

                ElevatedButton.icon(
                  onPressed: _checkingForUpdates ? null : _checkForUpdates,
                  icon: _checkingForUpdates
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.system_update),
                  label: Text(_checkingForUpdates
                    ? 'Mijery vaovao...'
                    : 'Jereo vaovao',),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 45),
                    backgroundColor: Colors.yellow,
                  ),
                ),

                const SizedBox(height: 10),

                if (_updateAvailable) ...[
                  ElevatedButton.icon(
                    onPressed: _checkingForUpdates ? null : _downloadAndInstallUpdate,
                    icon: _checkingForUpdates
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download),
                    label: Text(_flexibleUpdateDownloaded
                      ? 'Download & Install'
                      : (_checkingForUpdates ? 'Download...' : 'Download')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 45),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: _checkingForUpdates ? null : _performImmediateUpdate,
                    icon: const Icon(Icons.update),
                    label: const Text('Vaovao'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 45),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Text(
                  'Adiresy: Ambalavao tsienimparihy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'App version : $_appVersion',
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