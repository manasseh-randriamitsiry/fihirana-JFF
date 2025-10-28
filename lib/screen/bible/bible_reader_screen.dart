import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';
import '../../widgets/bible_book_list_item.dart';

// Enable GPU rasterization for better performance
class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final BibleController bibleController = Get.put(BibleController());
  final ColorController colorController = Get.find<ColorController>();
  
  final TextEditingController _searchController = TextEditingController();
  
  // Font size variables
  final double _baseFontSize = 18.0;
  final double _baseCountFontSize = 50.0;
  double _fontSize = 18.0;
  double _countFontSize = 50.0;
  bool _showSlider = false;

  @override
  void initState() {
    super.initState();
    // Enable GPU rasterization for better performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This helps with rendering performance
    });
    _loadFontSize();
  }
  
  void _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? _baseFontSize;
      _countFontSize = prefs.getDouble('countFontSize') ?? _baseCountFontSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorController.iconColor.value),
            onPressed: () => Navigator.pop(context),
          ),
          title: Obx(() {
            // Show book name and chapter when viewing a passage
            if (bibleController.selectedBook.isNotEmpty && bibleController.selectedChapter.value > 0) {
              return Text(
                '${bibleController.selectedBook.value} ${bibleController.selectedChapter.value}',
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontWeight: FontWeight.bold,
                  fontSize: _fontSize, // Use user-defined font size
                ),
              );
            } 
            // Show "Famakiana Baiboly" when selecting books or chapters
            else {
              return Text(
                'Famakiana Baiboly',
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontWeight: FontWeight.bold,
                  fontSize: _fontSize, // Use user-defined font size
                ),
              );
            }
          }),
          actions: [
            // Font size adjustment button
            IconButton(
              icon: Icon(Icons.text_fields, color: colorController.iconColor.value),
              onPressed: () {
                setState(() {
                  _showSlider = !_showSlider;
                });
              },
            ),
            // Add save highlight button when verses are selected
            Obx(() {
              if (bibleController.startVerse.value > 0) {
                return IconButton(
                  icon: Icon(Icons.bookmark_add, color: colorController.iconColor.value),
                  onPressed: _saveHighlight,
                );
              }
              return const SizedBox.shrink();
            }),
            // Add share button when verses are selected
            Obx(() {
              if (bibleController.startVerse.value > 0) {
                return IconButton(
                  icon: Icon(Icons.share, color: colorController.iconColor.value),
                  onPressed: _shareSelectedVerses,
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        body: Obx(() {
          return _buildContentArea(colorController);
        }),
      ),
    );
  }
  
  Widget _buildContentArea(ColorController colorController) {
    // Book list view
    if (bibleController.selectedBook.isEmpty) {
      return Column(
        children: [
          // Search bar only for book selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Karoka boky...',
                labelStyle: TextStyle(color: colorController.textColor.value),
                prefixIcon: Icon(Icons.search, color: colorController.iconColor.value),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorController.textColor.value.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorController.textColor.value.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorController.primaryColor.value,
                  ),
                ),
              ),
              style: TextStyle(color: colorController.textColor.value),
              onChanged: bibleController.searchBooks,
            ),
          ),
          // Font size slider
          if (_showSlider)
            Slider(
              value: _fontSize,
              min: 12,
              max: 40,
              divisions: 28,
              label: _fontSize.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _fontSize = value;
                  _countFontSize = value * (_baseCountFontSize / _baseFontSize);
                });
              },
              onChangeEnd: (double value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('fontSize', value);
                setState(() {
                  _showSlider = false;
                });
              },
            ),
          // Book list
          Expanded(
            child: bibleController.isLoading.value
                ? _buildLoadingIndicator(bibleController.loadingMessage.value, colorController)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: bibleController.bookList.length,
                    // Add performance optimizations
                    cacheExtent: 1000, // Cache more items
                    itemBuilder: (context, index) {
                      final bookName = bibleController.bookList[index];
                      final chapterCount = bibleController.getChapterCountForBook(bookName);
                      return BibleBookListItem(
                        bookName: bookName,
                        chapterCount: chapterCount,
                        textColor: colorController.textColor.value,
                        backgroundColor: colorController.backgroundColor.value,
                        onTap: () => bibleController.selectBook(bookName),
                      );
                    },
                  ),
          ),
        ],
      );
    }
    
    // Chapter selection view (full screen)
    if (bibleController.selectedChapter.value == 0) {
      return Column(
        children: [
          // Header with book info
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: colorController.textColor.value.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colorController.iconColor.value),
                  onPressed: () {
                    bibleController.selectedBook.value = '';
                    bibleController.chapterList.clear();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bibleController.selectedBook.value,
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: _fontSize * 1.2, // Larger font for book title
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Font size slider
          if (_showSlider)
            Slider(
              value: _fontSize,
              min: 12,
              max: 40,
              divisions: 28,
              label: _fontSize.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _fontSize = value;
                  _countFontSize = value * (_baseCountFontSize / _baseFontSize);
                });
              },
              onChangeEnd: (double value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('fontSize', value);
                setState(() {
                  _showSlider = false;
                });
              },
            ),
          // Chapter grid (full screen)
          Expanded(
            child: bibleController.chapterList.isEmpty
                ? const Center(child: Text('Tsy misy toko'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: bibleController.chapterList.length,
                    // Add performance optimizations
                    cacheExtent: 500,
                    itemBuilder: (context, index) {
                      final chapter = bibleController.chapterList[index];
                      return Card(
                        elevation: 4,
                        color: colorController.primaryColor.value,
                        child: InkWell(
                          onTap: () => bibleController.selectChapter(chapter),
                          child: Center(
                            child: Text(
                              chapter.toString(),
                              style: TextStyle(
                                color: colorController.backgroundColor.value,
                                fontWeight: FontWeight.bold,
                                fontSize: _fontSize * 1.2, // Larger font for chapter numbers
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }
    
    // Passage display view (full screen)
    return Column(
      children: [
        
        // Font size slider
        if (_showSlider)
          Slider(
            value: _fontSize,
            min: 12,
            max: 40,
            divisions: 28,
            label: _fontSize.round().toString(),
            onChanged: (double value) {
              setState(() {
                _fontSize = value;
                _countFontSize = value * (_baseCountFontSize / _baseFontSize);
              });
            },
            onChangeEnd: (double value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('fontSize', value);
              setState(() {
                _showSlider = false;
              });
            },
          ),
        
        // Verse selection controls (only visible when selecting)
        Obx(() {
          if (bibleController.isSelecting.value && bibleController.startVerse.value > 0) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorController.backgroundColor.value,
                border: Border(
                  bottom: BorderSide(
                    color: colorController.textColor.value.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Famaritaka: ${bibleController.startVerse.value}-${bibleController.endVerse.value}',
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontWeight: FontWeight.bold,
                      fontSize: _fontSize, // Use user-defined font size
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: colorController.iconColor.value),
                        onPressed: () {
                          bibleController.startVerse.value = 0;
                          bibleController.endVerse.value = 0;
                          bibleController.isSelecting.value = false;
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          bibleController.endVerseSelection();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        
        // Passage content (full screen)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: bibleController.isLoading.value
                ? _buildLoadingIndicator(bibleController.loadingMessage.value, colorController)
                : bibleController.passageText.isEmpty
                    ? const Center(child: Text('Tsy misy andininy'))
                    : _buildPassageContent(colorController),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPassageContent(ColorController colorController) {
    // Parse the passage text and create selectable verses
    final verses = <Map<String, dynamic>>[];
    final lines = bibleController.passageText.value.split('\n\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Extract verse number and text
      final match = RegExp(r'^(\d+)\.\s(.*)$').firstMatch(line);
      if (match != null) {
        final verseNum = int.tryParse(match.group(1) ?? '0') ?? 0;
        final verseText = match.group(2) ?? '';
        
        verses.add({
          'number': verseNum,
          'text': verseText,
        });
      }
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...verses.map((verse) {
            final verseNum = verse['number'] as int;
            final verseText = verse['text'] as String;
            
            return Obx(() {
              final isSelected = bibleController.isVerseSelected(verseNum);
              final isHighlighted = bibleController.isVerseHighlighted(verseNum);
              final isInRange = bibleController.isSelecting.value && 
                               verseNum >= bibleController.startVerse.value && 
                               verseNum <= bibleController.endVerse.value;
              
              return GestureDetector(
                onTap: () {
                  if (!bibleController.isSelecting.value) {
                    bibleController.startVerseSelection(verseNum);
                  } else {
                    bibleController.updateVerseSelection(verseNum);
                  }
                },
                onDoubleTap: () {
                  // Double tap to select single verse
                  bibleController.startVerseSelection(verseNum);
                  bibleController.endVerseSelection();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected || isInRange
                        ? colorController.primaryColor.value.withOpacity(0.3) 
                        : isHighlighted
                            ? Colors.yellow.withOpacity(0.3)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHighlighted 
                          ? Colors.yellow 
                          : isSelected || isInRange
                              ? colorController.primaryColor.value
                              : Colors.transparent,
                      width: isHighlighted || isSelected || isInRange ? 2 : 0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Verse number background
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$verseNum',
                              style: TextStyle(
                                fontSize: _countFontSize * 0.8, // Smaller background number
                                fontWeight: FontWeight.bold,
                                color: colorController.primaryColor.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Verse content
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: _fontSize, // Use user-defined font size
                              height: 1.6,
                            ),
                            children: [
                              TextSpan(
                                text: '$verseNum. ',
                                style: TextStyle(
                                  fontWeight: isSelected || isHighlighted || isInRange ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected || isHighlighted || isInRange
                                      ? colorController.primaryColor.value 
                                      : colorController.textColor.value,
                                ),
                              ),
                              TextSpan(
                                text: verseText,
                                style: TextStyle(
                                  color: isSelected || isHighlighted || isInRange
                                      ? colorController.primaryColor.value 
                                      : colorController.textColor.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
        ],
      ),
    );
  }
  
  void _saveHighlight() {
    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      Get.snackbar('Fahazoandàlana', 'Il faut se connecter pour enregistrer les marques.', backgroundColor: Colors.red);
      return;
    }
    
    bibleController.saveHighlight();
  }
  
  void _shareSelectedVerses() {
    final selectedRange = bibleController.getSelectedVerseRange();
    if (selectedRange.isNotEmpty) {
      // In a real implementation, you would use a sharing plugin here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hafainganana: $selectedRange'),
          backgroundColor: colorController.primaryColor.value,
        ),
      );
    }
  }
  
  Widget _buildLoadingIndicator(String message, ColorController colorController) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Container(
              height: 8,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorController.primaryColor.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Loading message
            Text(
              message,
              style: TextStyle(
                fontSize: _fontSize, // Use user-defined font size
                color: colorController.textColor.value,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            // Additional info
            Text(
              'Mahandrasa kely azafady...',
              style: TextStyle(
                fontSize: _fontSize * 0.8, // Smaller font for additional info
                color: colorController.textColor.value.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}