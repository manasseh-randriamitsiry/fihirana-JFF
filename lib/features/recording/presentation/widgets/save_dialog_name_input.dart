import 'package:flutter/material.dart';

class SaveDialogNameInput extends StatelessWidget {
  final TextEditingController nameController;

  const SaveDialogNameInput({
    super.key,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: nameController,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [],
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.text,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      decoration: InputDecoration(
        labelText: 'Recording Name',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        prefixIcon: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.8)),
      ),
    );
  }
}