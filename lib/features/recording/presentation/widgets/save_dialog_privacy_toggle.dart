import 'package:flutter/material.dart';

class SaveDialogPrivacyToggle extends StatefulWidget {
  final bool initialValue;
  final Function(bool) onChanged;

  const SaveDialogPrivacyToggle({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<SaveDialogPrivacyToggle> createState() =>
      _SaveDialogPrivacyToggleState();
}

class _SaveDialogPrivacyToggleState extends State<SaveDialogPrivacyToggle> {
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          _isPublic ? 'Enregistrement public' : 'Enregistrement privé',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isPublic
              ? 'Tout le monde peut écouter cet enregistrement'
              : 'Vous seul pouvez écouter cet enregistrement',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        value: _isPublic,
        onChanged: (value) {
          setState(() => _isPublic = value);
          widget.onChanged(value);
        },
        activeTrackColor: Colors.white,
        inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}
