import 'package:flutter/material.dart';

import 'package:fihirana/shared/widgets/common/app_ui.dart';

class AboutSectionTitleWidget extends StatelessWidget {
  final String title;

  const AboutSectionTitleWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: .2,
          ),
    );
  }
}

class AboutActionCardWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final int animationDelay;

  const AboutActionCardWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppGroupedSurface(
      children: [
        AppListRow(
          icon: icon,
          iconColor: iconColor,
          title: label,
          onTap: onTap,
        ),
      ],
    );
  }
}

class AboutStatCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const AboutStatCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppGroupedSurface(
      children: [
        AppListRow(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          trailing: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
