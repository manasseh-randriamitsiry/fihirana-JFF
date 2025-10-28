import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final BibleController bibleController = Get.put(BibleController());
  final ColorController colorController = Get.find<ColorController>();
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
          title: Text(
            'Famakiana Baiboly',
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Obx(() {
          return Column(
            children: [
              // Book selection
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
              
              // Content area - use Expanded to take remaining space
              Expanded(
                child: Container(
                  child: _buildContentArea(colorController),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  Widget _buildContentArea(ColorController colorController) {
    // Book list view
    if (bibleController.selectedBook.isEmpty) {
      return bibleController.isLoading.value
          ? _buildLoadingIndicator(bibleController.loadingMessage.value, colorController)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: bibleController.bookList.length,
              itemBuilder: (context, index) {
                final bookName = bibleController.bookList[index];
                return Card(
                  color: colorController.backgroundColor.value,
                  child: ListTile(
                    title: Text(
                      bookName,
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => bibleController.selectBook(bookName),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: colorController.iconColor.value,
                      size: 16,
                    ),
                  ),
                );
              },
            );
    }
    
    // Chapter selection view
    if (bibleController.selectedChapter.value == 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                Text(
                  bibleController.selectedBook.value,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: bibleController.chapterList.isEmpty
                ? const Center(child: Text('Tsy misy toko'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: bibleController.chapterList.length,
                    itemBuilder: (context, index) {
                      final chapter = bibleController.chapterList[index];
                      return Card(
                        color: colorController.primaryColor.value,
                        child: InkWell(
                          onTap: () => bibleController.selectChapter(chapter),
                          child: Center(
                            child: Text(
                              chapter.toString(),
                              style: TextStyle(
                                color: colorController.backgroundColor.value,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
    
    // Passage display view
    return Column(
      children: [
        // Header with book info and navigation
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colorController.iconColor.value),
                onPressed: () {
                  bibleController.selectedChapter.value = 0;
                  bibleController.passageText.value = '';
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${bibleController.selectedBook.value} ${bibleController.selectedChapter.value}',
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Previous chapter
              if (bibleController.selectedChapter.value > 1)
                IconButton(
                  icon: Icon(Icons.skip_previous, color: colorController.iconColor.value),
                  onPressed: () => bibleController.selectChapter(bibleController.selectedChapter.value - 1),
                ),
              // Next chapter
              if (bibleController.chapterList.isNotEmpty && 
                  bibleController.selectedChapter.value < bibleController.chapterList.last)
                IconButton(
                  icon: Icon(Icons.skip_next, color: colorController.iconColor.value),
                  onPressed: () => bibleController.selectChapter(bibleController.selectedChapter.value + 1),
                ),
            ],
          ),
        ),
        
        // Passage content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: bibleController.isLoading.value
                ? _buildLoadingIndicator(bibleController.loadingMessage.value, colorController)
                : bibleController.passageText.isEmpty
                    ? const Center(child: Text('Tsy misy andininy'))
                    : SingleChildScrollView(
                        child: Text(
                          bibleController.passageText.value,
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
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
                fontSize: 16,
                color: colorController.textColor.value,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            // Additional info
            Text(
              'Mahandrasa kely azafady...',
              style: TextStyle(
                fontSize: 14,
                color: colorController.textColor.value.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}