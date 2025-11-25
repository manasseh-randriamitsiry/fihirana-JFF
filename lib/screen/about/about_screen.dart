import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:fihirana/services/pubspec_service.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _appName = 'Fihirana';
  bool _checkingForUpdates = false;
  bool _downloadingUpdate = false;
  bool _updateAvailable = false;
  bool _flexibleUpdateDownloaded = false;
  String? _latestVersion;
  String? _releaseNotes;
  final ColorController colorController = Get.find<ColorController>();

  @override
  void initState() {
    super.initState();
    PubspecService.clearCache();
    _getAppInfo();

    // Check if update info is already cached from startup check
    if (VersionCheckService.hasUpdateCached()) {
      _updateAvailable = true;
      _latestVersion = VersionCheckService.getCachedVersion();
      _releaseNotes = VersionCheckService.getCachedReleaseNotes();
    }

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

          // Get cached version info if update is available
          if (updateAvailable) {
            _latestVersion = VersionCheckService.getCachedVersion();
            _releaseNotes = VersionCheckService.getCachedReleaseNotes();
          }
        });

        // Show "up to date" message if no update is available
        if (!updateAvailable && context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.appIsUpToDate),
              backgroundColor: Colors.green,
            ),
          );
        }
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
        _downloadingUpdate = true;
      });

      await VersionCheckService.downloadAndInstallLatestVersion();
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingUpdate = false;
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
          _downloadingUpdate = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorController.textColor.value.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: backgroundColor ?? colorController.backgroundColor.value,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorController.primaryColor.value)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? colorController.primaryColor.value,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: iconColor ?? colorController.textColor.value,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorController.textColor.value.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.aboutUs,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
          icon: Icon(
            Icons.menu_rounded,
            color: colorController.iconColor.value,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: colorController.primaryColor.value.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorController.primaryColor.value
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 60,
                        color: colorController.primaryColor.value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_appName ${l10n.appNameSuffix}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorController.textColor.value,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.appVersion(_appVersion),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorController.textColor.value
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.headquarters} ${l10n.headquartersAddress}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorController.textColor.value
                            .withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),

            // Contact Section
            _buildSectionTitle('Contact')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 100)),

            _buildActionCard(
              icon: Icons.phone_rounded,
              label: l10n.phoneNumber,
              onTap: () => _makePhoneCall('+261342943971'),
            )
                .animate()
                .fadeIn(
                    delay: const Duration(milliseconds: 150),
                    duration: const Duration(milliseconds: 300))
                .slideX(begin: -0.1, end: 0),

            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.email_rounded,
              label: l10n.email,
              onTap: () => _sendEmail('manassehrandriamitsiry@gmail.com'),
            )
                .animate()
                .fadeIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 300))
                .slideX(begin: -0.1, end: 0),

            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.code_rounded,
              label: l10n.portfolio,
              onTap: () =>
                  _launchURL('https://manassehrandriamitsiry.netlify.app/'),
            )
                .animate()
                .fadeIn(
                    delay: const Duration(milliseconds: 250),
                    duration: const Duration(milliseconds: 300))
                .slideX(begin: -0.1, end: 0),

            // Support Section
            _buildSectionTitle('Support')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300)),

            _buildActionCard(
              icon: Icons.monetization_on_rounded,
              label: l10n.support,
              onTap: () => _makePhoneCall('*111*1*2*0342943971#'),
              iconColor: Colors.green,
              backgroundColor: Colors.green.withValues(alpha: 0.05),
            )
                .animate()
                .fadeIn(
                    delay: const Duration(milliseconds: 350),
                    duration: const Duration(milliseconds: 300))
                .slideX(begin: -0.1, end: 0),

            // Updates Section
            _buildSectionTitle('Updates')
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400)),

            Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorController.textColor.value.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              color: colorController.backgroundColor.value,
              child: InkWell(
                onTap: (_checkingForUpdates || _downloadingUpdate) ? null : _checkForUpdates,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                       child: Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: colorController.primaryColor.value
                                   .withValues(alpha: 0.15),
                               shape: BoxShape.circle,
                             ),
                             child: (_checkingForUpdates || _downloadingUpdate)
                                 ? SizedBox(
                                     width: 24,
                                     height: 24,
                                     child: CircularProgressIndicator(
                                       strokeWidth: 2.5,
                                       valueColor: AlwaysStoppedAnimation<Color>(
                                           colorController.primaryColor.value),
                                     ),
                                   )
                                 : Icon(
                                     Icons.system_update_rounded,
                                     color: colorController.primaryColor.value,
                                     size: 24,
                                   ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Text(
                               _downloadingUpdate
                                   ? l10n.downloading
                                   : _checkingForUpdates
                                       ? l10n.checkingForUpdates
                                       : l10n.checkForUpdates,
                               style: TextStyle(
                                 color: colorController.textColor.value,
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ),
                           if (!_checkingForUpdates && !_downloadingUpdate)
                             Icon(
                               Icons.arrow_forward_ios,
                               size: 16,
                               color: colorController.textColor.value
                                   .withValues(alpha: 0.3),
                             ),
                         ],
                       ),
                ),
              ),
            )
                .animate()
                .fadeIn(
                    delay: const Duration(milliseconds: 450),
                    duration: const Duration(milliseconds: 300))
                .slideX(begin: -0.1, end: 0),

            // Show "Up to date" status when no updates available
            if (!_updateAvailable && (VersionCheckService.isUpToDate() || VersionCheckService.hasCheckedManually())) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                color: Colors.green.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.upToDate,
                              style: TextStyle(
                                color: colorController.textColor.value,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.appIsUpToDate,
                              style: TextStyle(
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .slideY(begin: -0.1, end: 0),
            ],

            if (_updateAvailable) ...[
              const SizedBox(height: 12),

              // Version info card
              Card(
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                color: Colors.orange.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.updateAvailableTitle,
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.currentVersion,
                                style: TextStyle(
                                  color: colorController.textColor.value
                                      .withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _appVersion,
                                style: TextStyle(
                                  color: colorController.textColor.value,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: colorController.textColor.value
                                .withValues(alpha: 0.4),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.latestVersion,
                                style: TextStyle(
                                  color: colorController.textColor.value
                                      .withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _latestVersion ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_releaseNotes != null &&
                          _releaseNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.whatsNew,
                          style: TextStyle(
                            color: colorController.textColor.value
                                .withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _releaseNotes!.length > 200
                              ? '${_releaseNotes!.substring(0, 200)}...'
                              : _releaseNotes!,
                          style: TextStyle(
                            color: colorController.textColor.value
                                .withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .slideY(begin: -0.1, end: 0),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: _downloadingUpdate ? Icons.downloading_rounded : Icons.download_rounded,
                label: _flexibleUpdateDownloaded
                    ? l10n.downloadAndInstall
                    : (_downloadingUpdate ? l10n.downloading : l10n.download),
                onTap: (_checkingForUpdates || _downloadingUpdate) ? () {} : _downloadAndInstallUpdate,
                iconColor: Colors.orange,
                backgroundColor: Colors.orange.withValues(alpha: 0.05),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .scale(curve: Curves.easeOutBack),
            ],

            const SizedBox(height: 32),

            // Developer Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorController.textColor.value.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.developedBy,
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Randriamitsiry Valimbavaka Nandrasana Manassé',
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.addressLabel} Ambalavao tsienimparihy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 400)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
