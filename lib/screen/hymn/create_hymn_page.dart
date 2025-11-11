import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';

class CreateHymnPage extends StatefulWidget {
  const CreateHymnPage({super.key});

  @override
  CreateHymnPageState createState() => CreateHymnPageState();
}

class CreateHymnPageState extends State<CreateHymnPage> {
  final _formKey = GlobalKey<FormState>();
  final _hymnNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _bridgeController = TextEditingController();
  final _hymnHintController = TextEditingController();
  final List<TextEditingController> _verseControllers = [TextEditingController()];
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void dispose() {

    _hymnNumberController.dispose();
    _titleController.dispose();
    _bridgeController.dispose();
    _hymnHintController.dispose();
    for (var controller in _verseControllers) {
      controller.dispose();
    }
    _debouncer.dispose();
    super.dispose();
  }

  void _clearForm() {

    if (!mounted) return;

    setState(() {
      _hymnNumberController.text = '';
      _titleController.text = '';
      for (var controller in _verseControllers) {
        controller.text = '';
      }

      while (_verseControllers.length > 1) {
        _verseControllers.removeLast();
      }
      _bridgeController.text = '';
      _hymnHintController.text = '';
    });
  }

  Future<void> _createHymn() async {
    if (!_formKey.currentState!.validate()) return;

    try {

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Get.find<ColorController>().primaryColor.value,
          ),
        ),
      );

      final hymn = Hymn(
        id: '',
        hymnNumber: _hymnNumberController.text.trim(),
        title: _titleController.text.trim(),
        verses: _verseControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
        bridge: _bridgeController.text.trim(),
        hymnHint: _hymnHintController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: '',
        createdByEmail: '',
      );

      final success = await Get.find<HymnService>().addHymn(hymn);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voasoratra soa aman-tsara ny hira',
              style: TextStyle(color: Get.find<ColorController>().textColor.value),
            ),
            backgroundColor: Get.find<ColorController>().backgroundColor.value,
          ),
        );
        _clearForm();
        Navigator.of(context).pop();
      }
    } catch (error) {

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nisy olana fa ialana tsiny: $error',
            style: TextStyle(color: Get.find<ColorController>().textColor.value),
          ),
          backgroundColor: Get.find<ColorController>().backgroundColor.value,
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
  }) {
    final colorController = Get.find<ColorController>();
    return Neumorphic(
      style: NeumorphicStyle(
        color: colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        depth: 2,
        intensity: 0.8,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: colorController.textColor.value),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorController.textColor.value),
          prefixIcon: icon != null
              ? NeumorphicIcon(icon, style: NeumorphicStyle(color: colorController.iconColor.value))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildVerseField(int index) {
    final colorController = Get.find<ColorController>();
    return Neumorphic(
      key: ValueKey(index),
      style: NeumorphicStyle(
        color: colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        depth: 3,
        intensity: 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _verseControllers[index],
                maxLines: null,
                style: TextStyle(color: colorController.textColor.value),
                decoration: InputDecoration(
                  labelText: 'Andininy ${index + 1}',
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {

                  _debouncer.run(() {
                    setState(() {});
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soraty ny andininy';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            NeumorphicButton(
              style: NeumorphicStyle(
                color: Colors.red.withOpacity(0.1),
                boxShape: NeumorphicBoxShape.circle(),
                depth: 2,
              ),
              child: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _verseControllers[index].dispose();
                  _verseControllers.removeAt(index);
                });
              },
            ),
            const SizedBox(width: 4),
            ReorderableDragStartListener(
              index: index,
              child: NeumorphicIcon(
                Icons.drag_handle, 
                style: NeumorphicStyle(color: colorController.iconColor.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = FirebaseAuth.instance.currentUser;
    if (!authController.isAdmin && !authController.canAddSongs) {
      return Scaffold(
        backgroundColor: Get.find<ColorController>().backgroundColor.value,
        appBar: AppBar(
          backgroundColor: Get.find<ColorController>().backgroundColor.value,
          elevation: 0,
          title: Text(
            'Hamorona hira',
            style: TextStyle(
              color: Get.find<ColorController>().textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_outlined, 
              color: Get.find<ColorController>().iconColor.value,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Neumorphic(
            style: NeumorphicStyle(
              color: Get.find<ColorController>().backgroundColor.value,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
              depth: 4,
              intensity: 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Salama ${user?.email},\nNoho ny antony manokana dia tsy mbolo mahazo alalana hamorona hira ianao.'
                '\nMahandrasa kely azafady.'
                '\nNa Antsoy ny admin (manassé) hanome alalana.',
                style: TextStyle(color: Get.find<ColorController>().textColor.value),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_ios_outlined,
              color: colorController.iconColor.value,
            ),
          ),
          title: Text(
            'Mampiditra hira',
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _hymnNumberController,
                    label: 'Laharana',
                    keyboardType: TextInputType.number,
                    icon: Icons.onetwothree_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Apidiro ny laharan'ny hira";
                      }
                      try {
                        int? number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return "Laharana tsy mety";
                        }
                      } catch (e) {
                        return "Laharana tsy mety";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Lohateny',
                    icon: Icons.title,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Soraty ny lohateny';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Neumorphic(
                    style: NeumorphicStyle(
                      color: colorController.backgroundColor.value,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                      depth: 2,
                      intensity: 0.8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: Text(
                        'Andininy',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: colorController.textColor.value,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _verseControllers.removeAt(oldIndex);
                        _verseControllers.insert(newIndex, item);
                      });
                    },
                    children: List.generate(_verseControllers.length, (index) {
                      return _buildVerseField(index);
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: NeumorphicButton(
                      style: NeumorphicStyle(
                        color: colorController.primaryColor.value.withOpacity(0.1),
                        boxShape: NeumorphicBoxShape.circle(),
                        depth: 3,
                        intensity: 0.8,
                      ),
                      child: Icon(
                        Icons.add_circle,
                        color: colorController.primaryColor.value,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _verseControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _bridgeController,
                    label: 'Fiverenany (Raha misy)',
                    maxLines: 3,
                    icon: Icons.repeat,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _hymnHintController,
                    label: 'Naoty',
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 24.0),
                  NeumorphicButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _createHymn();
                      }
                    },
                    style: NeumorphicStyle(
                      color: colorController.primaryColor.value,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                      depth: 4,
                      intensity: 0.8,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Apidiro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorController.textColor.value,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  bool _isDisposed = false;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_isDisposed) return;

    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
