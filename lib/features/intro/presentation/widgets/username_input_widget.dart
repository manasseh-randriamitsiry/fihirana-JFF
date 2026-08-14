import 'package:flutter/material.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class UsernameInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool enabled;
  final Color? accentColor;

  const UsernameInputWidget({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
    this.accentColor,
  });

  @override
  State<UsernameInputWidget> createState() => _UsernameInputWidgetState();
}

class _UsernameInputWidgetState extends State<UsernameInputWidget> {
  late final TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_onTextChanged);
    _showClearButton = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final shouldShow = _controller.text.isNotEmpty;
    if (_showClearButton != shouldShow) {
      setState(() {
        _showClearButton = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      maxLength: 15,
      enabled: widget.enabled,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.givenName, AutofillHints.nickname],
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
            color: widget.accentColor ?? Theme.of(context).colorScheme.primary),
        prefixIcon: Icon(
          Icons.person_outline,
          color: widget.accentColor ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        suffixIcon: _showClearButton && widget.enabled
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  widget.controller.clear();
                },
                tooltip: l10n.clearName,
              )
            : null,
        counterText: '',
        hintText: l10n.enterNameHint,
      ),
    );
  }
}

class UsernameHelperTextWidget extends StatelessWidget {
  final TextEditingController controller;
  final int minLength;

  const UsernameHelperTextWidget({
    super.key,
    required this.controller,
    this.minLength = 4,
  });

  @override
  Widget build(BuildContext context) {
    final currentLength = controller.text.trim().length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '$currentLength/15 caractères (minimum $minLength)',
        style: TextStyle(
          fontSize: 12,
          color: currentLength >= minLength
              ? Colors.green.shade700
              : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
