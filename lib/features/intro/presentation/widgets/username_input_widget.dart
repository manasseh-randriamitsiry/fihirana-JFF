import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: widget.controller,
        maxLength: 15,
        enabled: widget.enabled,
        keyboardType: TextInputType.name,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.givenName, AutofillHints.nickname],
        style: const TextStyle(
          fontSize: 16, // Slightly larger for better readability
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: widget.accentColor ?? Colors.green.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.person_outline,
            color: widget.accentColor ?? Colors.green.shade600,
            size: 24,
          ),
          suffixIcon: _showClearButton && widget.enabled
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: () {
                    widget.controller.clear();
                  },
                  tooltip: 'Clear',
                )
              : null,
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: 'Enter your name',
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
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
        '$currentLength/15 characters (minimum $minLength)',
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
