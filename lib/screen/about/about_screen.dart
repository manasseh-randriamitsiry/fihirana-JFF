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
    
    // Set callbacks for update availability and flexible update completion
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
      // Check for updates using the VersionCheckService
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
        
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tsy afaka mijery rindrambaiko'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadAndInstallUpdate() async {
    try {
      // Check if flexible update is already downloaded
      if (VersionCheckService.isFlexibleUpdateAvailable()) {
        // Complete the flexible update
        await VersionCheckService.completeFlexibleUpdate();
      } else {
        // Start a flexible update
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
        
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tsy afaka mandefa ny fakàna'),
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
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tsy afaka mandefa ny fanavaozana'),
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
                
                // Update Check Button
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
                    ? 'Mijery rindrambaiko...' 
                    : 'Jereo rindrambaiko'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 45),
                    backgroundColor: Colors.blue,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Download and Install Update Button (only shown when update is available)
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
                      ? 'Apetraho ny vaovao' 
                      : (_checkingForUpdates ? 'Mandefa fakàna...' : 'Fakàna & Apetraho')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 45),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Immediate Update Button
                  ElevatedButton.icon(
                    onPressed: _checkingForUpdates ? null : _performImmediateUpdate,
                    icon: const Icon(Icons.update),
                    label: const Text('Vaovao haingana'),
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