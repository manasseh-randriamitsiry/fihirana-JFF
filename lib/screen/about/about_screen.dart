import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';

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
  final ColorController colorController = Get.find<ColorController>();

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
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '?',
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_outlined,
            color: colorController.iconColor.value,
          ),
        ),
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
                Neumorphic(
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Fihirana JFF',
                  style: TextStyle(fontSize: 18, color: colorController.textColor.value),
                ),
                const SizedBox(height: 5),
                Text(
                  'Foibe: Antsororokavo Fianarantsoa 301',
                  style: TextStyle(fontSize: 18, color: colorController.textColor.value),
                ),
                const SizedBox(height: 20),
                NeumorphicButton(
                  onPressed: () => _makePhoneCall('+261342943971'),
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                  child: Container(
                    width: 250,
                    height: 45,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          '+261 34 29 439 71',
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                NeumorphicButton(
                  onPressed: () => _sendEmail('manassehrandriamitsiry@gmail.com'),
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                  child: Container(
                    width: 250,
                    height: 45,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          'Email',
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                NeumorphicButton(
                  onPressed: () => _launchURL('https://github.com/manasseh-randriamitsiry'),
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                  child: Container(
                    width: 250,
                    height: 45,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code, color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          'GitHub',
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                NeumorphicButton(
                  onPressed: () => _makePhoneCall('*111*1*2*0342943971#'),
                  style: NeumorphicStyle(
                    color: Colors.green.withOpacity(0.1),
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                  child: Container(
                    width: 250,
                    height: 45,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'fanohanana',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                NeumorphicButton(
                  onPressed: _checkingForUpdates ? null : _checkForUpdates,
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                  child: Container(
                    width: 250,
                    height: 45,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _checkingForUpdates
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(colorController.primaryColor.value),
                              ),
                            )
                          : Icon(Icons.system_update, color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          _checkingForUpdates ? 'vaovao...' : 'vaovao',
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (_updateAvailable) ...[
                  NeumorphicButton(
                    onPressed: _checkingForUpdates ? null : _downloadAndInstallUpdate,
                    style: NeumorphicStyle(
                      color: Colors.orange.withOpacity(0.1),
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                      depth: 4,
                      intensity: 0.8,
                    ),
                    child: Container(
                      width: 250,
                      height: 45,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _checkingForUpdates
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                ),
                              )
                            : const Icon(Icons.download, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            _flexibleUpdateDownloaded
                              ? 'Download & Install'
                              : (_checkingForUpdates ? 'Download...' : 'Download'),
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  NeumorphicButton(
                    onPressed: _checkingForUpdates ? null : _performImmediateUpdate,
                    style: NeumorphicStyle(
                      color: Colors.red.withOpacity(0.1),
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                      depth: 4,
                      intensity: 0.8,
                    ),
                    child: Container(
                      width: 250,
                      height: 45,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.update, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Vaovao',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'By Randriamitsiry Valimbavaka Nandrasana Manassé',
                  style: TextStyle(color: colorController.textColor.value),
                ),
                Text(
                  'Adiresy: Ambalavao tsienimparihy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}