import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_form_widgets.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class EditHymnScreen extends StatefulWidget {
  final Hymn hymn;

  const EditHymnScreen({super.key, required this.hymn});

  @override
  State<EditHymnScreen> createState() => _EditHymnScreenState();
}

class _EditHymnScreenState extends State<EditHymnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hymnNumberController = TextEditingController();
  final _bridgeController = TextEditingController();
  final _hymnHintController = TextEditingController();
  late final List<TextEditingController> _verseControllers;
  final HymnService _hymnService = HymnService();

  @override
  void initState() {
    super.initState();
    _hymnNumberController.text = widget.hymn.hymnNumber;
    _titleController.text = widget.hymn.title;
    _hymnHintController.text = widget.hymn.hymnHint ?? '';
    _bridgeController.text = widget.hymn.bridge ?? '';
    _verseControllers = widget.hymn.verses
        .map((verse) => TextEditingController(text: verse))
        .toList();
  }

  @override
  void dispose() {
    _hymnNumberController.dispose();
    _titleController.dispose();
    _bridgeController.dispose();
    _hymnHintController.dispose();
    for (final controller in _verseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isUserAuthenticated => FirebaseAuth.instance.currentUser != null;

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (!_isUserAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.loginRequired), backgroundColor: colors.error),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final updatedHymn = Hymn(
      id: widget.hymn.id,
      hymnNumber: _hymnNumberController.text.trim(),
      title: _titleController.text.trim(),
      verses: _verseControllers
          .map((controller) => controller.text.trim())
          .where((verse) => verse.isNotEmpty)
          .toList(),
      bridge: _bridgeController.text.trim(),
      hymnHint: _hymnHintController.text.trim(),
      createdAt: widget.hymn.createdAt,
      createdBy: widget.hymn.createdBy,
      createdByEmail: widget.hymn.createdByEmail,
    );

    try {
      await _hymnService.updateHymn(updatedHymn.id, updatedHymn);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.hymnUpdatedSuccessfully),
          backgroundColor: colors.primary,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdating(error.toString())),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.edit} ${widget.hymn.hymnNumber}'),
        actions: [
          if (_isUserAuthenticated)
            IconButton(
              tooltip: l10n.save,
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            AppSection(
              title: 'Informations',
              child: Column(
                children: [
                  FormTextFieldWidget(
                    controller: _hymnNumberController,
                    label: l10n.number,
                    icon: Icons.tag_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterHymnNumber;
                      }
                      final number = int.tryParse(value);
                      return number == null || number <= 0
                          ? l10n.invalidNumber
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  FormTextFieldWidget(
                    controller: _titleController,
                    label: l10n.title,
                    icon: Icons.title_rounded,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.enterTitle
                        : null,
                  ),
                ],
              ),
            ),
            AppSection(
              title: l10n.verses,
              child: Column(
                children: [
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Kept for compatibility with the Flutter SDK used in CI.
                    // ignore: deprecated_member_use
                    onReorder: _reorderVerses,
                    children: [
                      for (var index = 0;
                          index < _verseControllers.length;
                          index++)
                        Padding(
                          key: ValueKey('verse_$index'),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VerseFieldWidget(
                            index: index,
                            controller: _verseControllers[index],
                            onDelete: () => _deleteVerse(index),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _verseControllers.add(TextEditingController()),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.addVerse),
                    ),
                  ),
                ],
              ),
            ),
            AppSection(
              title: 'Compléments',
              child: Column(
                children: [
                  FormTextFieldWidget(
                    controller: _bridgeController,
                    label: l10n.bridge,
                    icon: Icons.repeat_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  FormTextFieldWidget(
                    controller: _hymnHintController,
                    label: l10n.notes,
                    icon: Icons.info_outline_rounded,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (_isUserAuthenticated)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: FilledButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.save),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _reorderVerses(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _verseControllers.removeAt(oldIndex);
      _verseControllers.insert(newIndex, item);
    });
  }

  void _deleteVerse(int index) {
    if (_verseControllers.length == 1) return;
    setState(() {
      _verseControllers[index].dispose();
      _verseControllers.removeAt(index);
    });
  }
}
