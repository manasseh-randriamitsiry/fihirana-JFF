import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'splash_widgets.dart';

class TermsAndConditionsWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final List<String> terms;

  const TermsAndConditionsWidget({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.terms,
  });

  @override
  State<TermsAndConditionsWidget> createState() =>
      _TermsAndConditionsWidgetState();
}

class _TermsAndConditionsWidgetState extends State<TermsAndConditionsWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IntroCardWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with expand/collapse button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.agreement,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.green,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onToggleExpanded();
                },
                tooltip: widget.isExpanded
                    ? 'Collapse'
                    : 'Expand to read full terms',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Collapsible terms content
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to expand and read full terms...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.terms
                  .map((term) => AgreementItemWidget(text: term))
                  .toList(),
            ),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
