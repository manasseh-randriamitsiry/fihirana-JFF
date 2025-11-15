import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:fihirana/services/pubspec_service.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '1.0.8';
  String _appName = 'Fihirana';
  bool _checkingForUpdates = false;
  bool _updateAvailable = false;
  bool _flexibleUpdateDownloaded = false;
  final ColorController colorController = Get.find<ColorController>();

  @override
  void initState() {
    super.initState();
    _getAppInfo();

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

  Future<void> _getAppInfo() async {
    final appVersion = await PubspecService.getAppVersion();
    final appName = await PubspecService.getAppName();
    setState(() {
      _appVersion = appVersion;
      _appName = appName;
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
      final updateAvailable =
          await VersionCheckService.checkForUpdateManually();

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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorCheckingUpdate),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadAndInstallUpdate() async {
    try {
      setState(() {
        _checkingForUpdates = true;
      });

      await VersionCheckService.downloadAndInstallLatestVersion();
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });

        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorDownloadingUpdate}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
                    depth: 4,
                    intensity: 0.8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 60,
                          color: colorController.primaryColor.value,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.appVersion(_appVersion),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorController.textColor.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_appName ${l10n.appNameSuffix}',
                  style: TextStyle(
                      fontSize: 18, color: colorController.textColor.value),
                ),
                const SizedBox(height: 5),
                Text(
                  '${l10n.headquarters} ${l10n.headquartersAddress}',
                  style: TextStyle(
                      fontSize: 18, color: colorController.textColor.value),
                ),
                const SizedBox(height: 20),
                NeumorphicButton(
                  onPressed: () => _makePhoneCall('+261342943971'),
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
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
                        Icon(Icons.phone,
                            color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          l10n.phoneNumber,
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                NeumorphicButton(
                  onPressed: () =>
                      _sendEmail('manassehrandriamitsiry@gmail.com'),
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
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
                        Icon(Icons.email,
                            color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          l10n.email,
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                NeumorphicButton(
                  onPressed: () =>
                      _launchURL('https://github.com/manasseh-randriamitsiry'),
                  style: NeumorphicStyle(
                    color: colorController.backgroundColor.value,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
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
                        Icon(Icons.code,
                            color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          l10n.github,
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                NeumorphicButton(
                  onPressed: () => _makePhoneCall('*111*1*2*0342943971#'),
                  style: NeumorphicStyle(
                    color: Colors.green.withValues(alpha: 0.1),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
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
                        Icon(Icons.monetization_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          l10n.support,
                          style: const TextStyle(color: Colors.green),
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
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colorController.primaryColor.value),
                                ),
                              )
                            : Icon(Icons.system_update,
                                color: colorController.iconColor.value),
                        const SizedBox(width: 8),
                        Text(
                          _checkingForUpdates
                              ? l10n.checkingForUpdates
                              : l10n.checkForUpdates,
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_updateAvailable) ...[
                  NeumorphicButton(
                    onPressed:
                        _checkingForUpdates ? null : _downloadAndInstallUpdate,
                    style: NeumorphicStyle(
                      color: Colors.orange.withValues(alpha: 0.1),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12)),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange),
                                  ),
                                )
                              : Icon(Icons.download, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            _flexibleUpdateDownloaded
                                ? l10n.downloadAndInstall
                                : (_checkingForUpdates
                                    ? l10n.downloading
                                    : l10n.download),
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                Text(
                  '${l10n.developedBy} Randriamitsiry Valimbavaka Nandrasana Manassé',
                  style: TextStyle(color: colorController.textColor.value),
                ),
                Text(
                  '${l10n.addressLabel} Ambalavao tsienimparihy',
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
