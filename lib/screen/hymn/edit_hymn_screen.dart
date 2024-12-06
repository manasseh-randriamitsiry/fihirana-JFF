import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../controller/color_controller.dart';

class EditHymnScreen extends StatefulWidget {
  final Hymn hymn;

  const EditHymnScreen({super.key, required this.hymn});

  @override
  EditHymnScreenState createState() => EditHymnScreenState();
}

class EditHymnScreenState extends State<EditHymnScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hymnNumberController = TextEditingController();
  final TextEditingController _bridgeController = TextEditingController();
  final TextEditingController _hymnHintController = TextEditingController();
  List<TextEditingController> _verseControllers = [];
  final ColorController colorController = Get.find<ColorController>();
  final HymnService _hymnService = HymnService();

  @override
  void initState() {
    super.initState();
    _hymnNumberController.text = widget.hymn.hymnNumber.toString();
    _titleController.text = widget.hymn.title;
    _hymnHintController.text = widget.hymn.hymnHint ?? "";
    _bridgeController.text = widget.hymn.bridge ?? "";

    // Initialize verse controllers and populate them with existing verses
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
    for (var controller in _verseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  void _saveChanges() {
    if (!isUserAuthenticated()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mila miditra aloha ianao'),
          backgroundColor: colorController.backgroundColor.value,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    
    // Convert hymn number to remove leading zeros
    final hymnNumber = int.parse(_hymnNumberController.text.trim()).toString();
    
    // Update the hymn object with new values
    Hymn updatedHymn = Hymn(
      id: widget.hymn.id,
      hymnNumber: hymnNumber,
      title: _titleController.text,
      verses: _verseControllers.map((controller) => controller.text).toList(),
      bridge: _bridgeController.text,
      hymnHint: _hymnHintController.text,
      createdAt: widget.hymn.createdAt,
      createdBy: widget.hymn.createdBy,
      createdByEmail: widget.hymn.createdByEmail,
    );

    // Call your Firestore update method from the service
    _hymnService
        .updateHymn(updatedHymn.id, updatedHymn)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voaova soa aman-tsara'),
              backgroundColor: colorController.backgroundColor.value,
            ),
          );
          Navigator.pop(context); // Navigate back after update
        })
        .catchError((error) {
          if (kDebugMode) {
            print('Error updating hymn: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nisy olana: $error'),
              backgroundColor: colorController.backgroundColor.value,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
          title: Text(
            'Hanova ny hira faha: ${widget.hymn.hymnNumber}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorController.textColor.value,
            ),
          ),
          actions: [
            if (isUserAuthenticated())
              IconButton(
                icon: Icon(Icons.save, color: colorController.iconColor.value),
                onPressed: _saveChanges,
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _hymnNumberController,
                  label: 'Laharan\'ny hira',
                  icon: Icons.onetwothree_outlined,
                  keyboardType: TextInputType.number,
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
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Andininy',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: colorController.textColor.value,
                  ),
                ),
                const SizedBox(height: 10),
                _buildVersesList(),
                const SizedBox(height: 16.0),
                _buildTextField(
                  controller: _bridgeController,
                  label: 'Fiverenany',
                  icon: Icons.repeat,
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  controller: _hymnHintController,
                  label: 'Fanamarihana',
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 16.0),
                if (isUserAuthenticated())
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: colorController.textColor.value,
                        backgroundColor: colorController.backgroundColor.value,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 40.0, right: 40, top: 20, bottom: 20),
                        child: Text(
                          "Apidiro",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: colorController.textColor.value),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorController.textColor.value),
        prefixIcon: Icon(icon, color: colorController.iconColor.value),
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
    );
  }

  Widget _buildVersesList() {
    return ReorderableListView(
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
              child: TextField(
                controller: _verseControllers[index],
                maxLines: null,
                style: TextStyle(color: colorController.textColor.value),
                decoration: InputDecoration(
                  labelText: 'Andininy ${index + 1}',
                  labelStyle: TextStyle(color: colorController.textColor.value),
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
                ),
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
              child: Icon(Icons.drag_handle, color: colorController.iconColor.value),
            ),
          ],
        ),
      ),
    );
  }
}
