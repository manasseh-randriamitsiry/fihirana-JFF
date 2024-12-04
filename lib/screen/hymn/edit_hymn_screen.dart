import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/hymn.dart';
import '../../services/hymn_service.dart';

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
        const SnackBar(
          content: Text('Mila miditra aloha ianao'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    // Update the hymn object with new values
    Hymn updatedHymn = Hymn(
      id: widget.hymn.id,
      hymnNumber: _hymnNumberController.text,
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
            const SnackBar(
              content: Text('Voaova soa aman-tsara'),
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hanova ny hira faha: ${widget.hymn.hymnNumber}',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          if (isUserAuthenticated())
            IconButton(
              icon: Icon(Icons.save, color: textColor),
              onPressed: () {
                _saveChanges();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _hymnNumberController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Laharan\'ny hira',
                  labelStyle: TextStyle(color: textColor),
                  prefixIcon:
                      Icon(Icons.onetwothree_outlined, color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Lohateny',
                  labelStyle: TextStyle(color: textColor),
                  prefixIcon: Icon(Icons.title, color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Andininy',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Use ReorderableListView for verses
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
                  return Padding(
                    key: Key('$index'),
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _verseControllers[index],
                            maxLines: null,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Andininy: ${index + 1}',
                              labelStyle: TextStyle(color: textColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: textColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: textColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: textColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        if (_verseControllers.length > 1)
                          CircleAvatar(
                            child: IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  _verseControllers.removeAt(index);
                                });
                              },
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _verseControllers.add(TextEditingController());
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _bridgeController,
                maxLines: null,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Fiverenana (Tsy voatery)',
                  labelStyle: TextStyle(color: textColor),
                  prefixIcon: Icon(Icons.refresh, color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _hymnHintController,
                maxLines: null,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Naoty',
                  labelStyle: TextStyle(color: textColor),
                  prefixIcon: Icon(Icons.note_alt_outlined, color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              if (isUserAuthenticated())
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveChanges();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: textColor,
                      backgroundColor: theme.primaryColor.withOpacity(0.2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(
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
    );
  }
}
