import 'package:flutter/material.dart';


class UsernameInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool enabled;

  const UsernameInputWidget({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
  });

  @override
  State<UsernameInputWidget> createState() => _UsernameInputWidgetState();
}

class _UsernameInputWidgetState extends State<UsernameInputWidget> {
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
        style: const TextStyle(fontSize: 15, color: Colors.black),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: const TextStyle(color: Colors.green, fontSize: 14),
          prefixIcon: const Icon(Icons.person_outline, color: Colors.green, size: 22),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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