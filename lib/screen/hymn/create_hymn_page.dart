import 'package:fihirana/controller/hymnController.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/color_controller.dart';

class CreateHymnPage extends StatefulWidget {
  const CreateHymnPage({super.key});

  @override
  CreateHymnPageState createState() => CreateHymnPageState();
}

class CreateHymnPageState extends State<CreateHymnPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _versesController = TextEditingController();
  final TextEditingController _bridgeController = TextEditingController();
  final TextEditingController _hymnNumberController = TextEditingController();
  final TextEditingController _hymnHintController = TextEditingController();
  final ColorController colorController = Get.find<ColorController>();

  List<TextEditingController> _verseControllers = [];
  final HymnController _hymnController = HymnController();

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: colorController.textColor.value),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorController.textColor.value),
        prefixIcon: icon != null
            ? Icon(icon, color: colorController.iconColor.value)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorController.textColor.value),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorController.textColor.value),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorController.primaryColor.value),
        ),
        fillColor: colorController.backgroundColor.value.withOpacity(0.1),
        filled: true,
      ),
      validator: validator,
    );
  }

  Widget _buildVerseField(int index) {
    return Card(
      key: ValueKey(index),
      color: colorController.backgroundColor.value,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: colorController.textColor.value),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: colorController.textColor.value),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: colorController.primaryColor.value),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soraty ny andininy';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: colorController.iconColor.value),
              onPressed: () {
                setState(() {
                  _verseControllers[index].dispose();
                  _verseControllers.removeAt(index);
                });
              },
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle,
                  color: colorController.iconColor.value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _verseControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _hymnNumberController.dispose();
    _titleController.dispose();
    _versesController.dispose();
    _bridgeController.dispose();
    _hymnHintController.dispose();
    for (var controller in _verseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = FirebaseAuth.instance.currentUser;
    if (!authController.isAdmin && !authController.canAddSongs) {
      return Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.primaryColor.value,
          title: Text(
            'Hamorona hira',
            style: TextStyle(color: colorController.textColor.value),
          ),
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back, color: colorController.iconColor.value),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Text(
            'Salama ${user?.email},\nNoho ny antony manokana dia tsy mbolola mahazo alalana hamorona hira ianao.'
            '\nMahandrasa kely azafady.'
            '\nNa Antsoy ny admin (manassé) hanome alalana.',
            style: TextStyle(color: colorController.textColor.value),
          ),
        ),
      );
    }

    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              colorController.textColor.value.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Text(
                      'Andininy',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: colorController.textColor.value,
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
                    child: IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: colorController.iconColor.value,
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
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: colorController.textColor.value),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _createHymn();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: colorController.textColor.value,
                        backgroundColor: colorController.backgroundColor.value,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Apidiro',
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

  Future<void> _createHymn() async {
    try {
      final hymnNumber = int.parse(_hymnNumberController.text.trim()).toString();
      final title = _titleController.text.trim();
      final verses = _verseControllers
          .map((controller) => controller.text.trim())
          .toList();
      final bridge = _bridgeController.text.isNotEmpty
          ? _bridgeController.text.trim()
          : null;
      final hymnHint = _hymnHintController.text.isNotEmpty
          ? _hymnHintController.text.trim()
          : null;

      if (await _hymnController.createHymn(
          hymnNumber, title, verses, bridge, hymnHint)) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voasoratra soa aman-tsara ny hira',
              style: TextStyle(color: colorController.textColor.value),
            ),
            backgroundColor: colorController.backgroundColor.value,
          ),
        );

        // Clear controllers and reset state after successful creation
        _hymnNumberController.clear();
        _titleController.clear();
        for (var controller in _verseControllers) {
          controller.clear();
        }
        _bridgeController.clear();
        _hymnHintController.clear();

        setState(() {
          _verseControllers = [TextEditingController()];
        });

        // Navigate back
        Navigator.pop(context);
      }
    } catch (error) {
      // Handle errors with themed colors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nisy olana fa ialana tsiny: $error',
            style: TextStyle(color: colorController.textColor.value),
          ),
          backgroundColor: colorController.backgroundColor.value,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
