import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/core/utils/pubspec_service.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

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

  @override
  void initState() {
    super.initState();
    PubspecService.clearCache();
    _getAppInfo();

    if (VersionCheckService.hasUpdateCached()) {
      _updateAvailable = true;
      _latestVersion = VersionCheckService.getCachedVersion();
      _releaseNotes = VersionCheckService.getCachedReleaseNotes();
    }

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() => _updateAvailable = true);
      }
    });
    VersionCheckService.setOnFlexibleUpdateDownloadedCallback(() {
      if (mounted) {
        setState(() => _flexibleUpdateDownloaded = true);
      }
    });
  }

  Future<void> _getAppInfo() async {
    final appVersion = await PubspecService.getAppVersion();
    final appName = await PubspecService.getAppName();
    if (!mounted) return;
    setState(() {
      _appVersion = appVersion;
      _appName = appName;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Impossible d’ouvrir $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) {
    return launchUrl(Uri(scheme: 'tel', path: phoneNumber));
  }

  Future<void> _sendEmail(String email) {
    return launchUrl(Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Contact depuis Fihirana&body=Bonjour,',
    ));
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingForUpdates = true);
    try {
      final updateAvailable =
          await VersionCheckService.checkForUpdateManually();
      if (!mounted) return;
      setState(() {
        _updateAvailable = updateAvailable;
        _checkingForUpdates = false;
        if (updateAvailable) {
          _latestVersion = VersionCheckService.getCachedVersion();
          _releaseNotes = VersionCheckService.getCachedReleaseNotes();
        }
      });
      if (!updateAvailable && mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).appIsUpToDate),
            backgroundColor: colors.primary,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingForUpdates = false);
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorCheckingUpdate),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  Future<void> _downloadAndInstallUpdate() async {
    setState(() => _downloadingUpdate = true);
    try {
      await VersionCheckService.downloadAndInstallLatestVersion();
    } catch (error) {
      if (!mounted) return;
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).errorDownloadingUpdate}: $error',
          ),
          backgroundColor: colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final busy = _checkingForUpdates || _downloadingUpdate;

    return AppPageScaffold(
      title: l10n.aboutUs,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: Get.find<ShellController>().toggleDrawer,
        icon: const Icon(Icons.menu_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppSection(
            title: 'Application',
            child: AppGroupedSurface(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(Icons.music_note_rounded, size: 42, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  '$_appName ${l10n.appNameSuffix}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.appVersion(_appVersion),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.headquarters} ${l10n.headquartersAddress}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppSection(
            title: 'Contact',
            child: AppGroupedSurface(
              children: [
                AppListRow(
                  icon: Icons.phone_rounded,
                  title: l10n.phoneNumber,
                  onTap: () => _makePhoneCall('+261342943971'),
                ),
                const AppGroupDivider(),
                AppListRow(
                  icon: Icons.email_rounded,
                  title: l10n.email,
                  onTap: () => _sendEmail('manassehrandriamitsiry@gmail.com'),
                ),
                const AppGroupDivider(),
                AppListRow(
                  icon: Icons.language_rounded,
                  title: l10n.portfolio,
                  onTap: () =>
                      _launchURL('https://manassehrandriamitsiry.netlify.app/'),
                ),
              ],
            ),
          ),
          AppSection(
            title: 'Soutien',
            child: AppGroupedSurface(
              children: [
                AppListRow(
                  icon: Icons.volunteer_activism_outlined,
                  title: l10n.support,
                  subtitle: 'Soutenir le développement de Fihirana',
                  onTap: () => _makePhoneCall('*111*1*2*0342943971#'),
                ),
              ],
            ),
          ),
          AppSection(
            title: 'Mises à jour',
            child: AppGroupedSurface(
              children: [
                AppListRow(
                  icon: Icons.system_update_rounded,
                  title: _downloadingUpdate
                      ? l10n.downloading
                      : _checkingForUpdates
                          ? l10n.checkingForUpdates
                          : l10n.checkForUpdates,
                  trailing: busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : null,
                  onTap: busy ? null : _checkForUpdates,
                ),
                if (!_updateAvailable &&
                    (VersionCheckService.isUpToDate() ||
                        VersionCheckService.hasCheckedManually())) ...[
                  const AppGroupDivider(),
                  AppListRow(
                    icon: Icons.check_circle_outline_rounded,
                    title: l10n.upToDate,
                    subtitle: l10n.appIsUpToDate,
                    trailing: const SizedBox.shrink(),
                    onTap: null,
                  ),
                ],
                if (_updateAvailable) ...[
                  const AppGroupDivider(),
                  AppListRow(
                    icon: Icons.new_releases_outlined,
                    title: l10n.updateAvailableTitle,
                    subtitle:
                        '${l10n.currentVersion}: $_appVersion  •  ${l10n.latestVersion}: ${_latestVersion ?? '—'}',
                    trailing: const SizedBox.shrink(),
                    onTap: null,
                  ),
                  if (_releaseNotes?.isNotEmpty == true) ...[
                    const AppGroupDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Text(
                        _releaseNotes!.length > 200
                            ? '${_releaseNotes!.substring(0, 200)}…'
                            : _releaseNotes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const AppGroupDivider(),
                  AppListRow(
                    icon: _flexibleUpdateDownloaded
                        ? Icons.install_mobile_outlined
                        : Icons.download_rounded,
                    title: _flexibleUpdateDownloaded
                        ? l10n.downloadAndInstall
                        : _downloadingUpdate
                            ? l10n.downloading
                            : l10n.download,
                    onTap: busy ? null : _downloadAndInstallUpdate,
                  ),
                ],
              ],
            ),
          ),
          AppSection(
            title: 'Développement',
            child: AppGroupedSurface(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.developedBy,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Randriamitsiry Valimbavaka Nandrasana Manassé',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.addressLabel} Ambalavao Tsienimparihy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
