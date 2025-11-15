class BibleBookOrder {
  // Mapping from English book names to Malagasy book names
  static const Map<String, String> englishToMalagasyMapping = {
    'Genesis': 'Genesisy',
    'Exodus': 'Eksodosy',
    'Leviticus': 'Levitikosy',
    'Numbers': 'Nomery',
    'Deuteronomy': 'Deoteronomia',
    'Joshua': 'Josoa',
    'Judges': 'Mpitsara',
    'Ruth': 'Rota',
    'I Samuel': '1 Samoela',
    'II Samuel': '2 Samoela',
    'I Kings': '1 Mpanjaka',
    'II Kings': '2 Mpanjaka',
    'I Chronicles': '1 Tantara',
    'II Chronicles': '2 Tantara',
    'Ezra': 'Ezra',
    'Nehemiah': 'Nehemia',
    'Esther': 'Estera',
    'Job': 'Joba',
    'Psalms': 'Salamo',
    'Proverbs': 'Ohabolana',
    'Ecclesiastes': 'Mpitoriteny',
    'Song of Solomon': 'Tonon-kiran\'i Solomona',
    'Isaiah': 'Isaia',
    'Jeremiah': 'Jeremia',
    'Lamentations': 'Fitomaniana',
    'Ezekiel': 'Ezekiela',
    'Daniel': 'Daniela',
    'Hosea': 'Hosea',
    'Joel': 'Joela',
    'Amos': 'Amosa',
    'Obadiah': 'Obadia',
    'Jonah': 'Jona',
    'Micah': 'Mika',
    'Nahum': 'Nahoma',
    'Habakkuk': 'Habakoka',
    'Zephaniah': 'Zefania',
    'Haggai': 'Hagay',
    'Zechariah': 'Zakaria',
    'Malachi': 'Malakia',
    'Matthew': 'Matio',
    'Mark': 'Marka',
    'Luke': 'Lioka',
    'John': 'Jaona',
    'Acts': 'Asan\'ny Apostoly',
    'Romans': 'Romanina',
    'I Corinthians': '1 Korintiana',
    'II Corinthians': '2 Korintiana',
    'Galatians': 'Galatiana',
    'Ephesians': 'Efesiana',
    'Philippians': 'Filipiana',
    'Colossians': 'Kolosiana',
    'I Thessalonians': '1 Tesalonisiana',
    'II Thessalonians': '2 Tesalonisiana',
    'I Timothy': '1 Timoty',
    'II Timothy': '2 Timoty',
    'Titus': 'Titosy',
    'Philemon': 'Filemona',
    'Hebrews': 'Hebreo',
    'James': 'Jakoba',
    'I Peter': '1 Petera',
    'II Peter': '2 Petera',
    'I John': '1 Jaona',
    'II John': '2 Jaona',
    'III John': '3 Jaona',
    'Jude': 'Joda',
    'Revelation of John': 'Apokalypsy',
  };

  // Old Testament books in correct biblical order (Testameta Taloha) - from order.txt
  static const List<String> oldTestamentOrder = [
    'Genesisy',
    'Eksodosy', 
    'Levitikosy',
    'Nomery',
    'Deoteronomia',
    'Josoa',
    'Mpitsara',
    'Rota',
    '1 Samoela',
    '2 Samoela',
    '1 Mpanjaka',
    '2 Mpanjaka',
    '1 Tantara',
    '2 Tantara',
    'Ezra',
    'Nehemia',
    'Estera',
    'Joba',
    'Salamo',
    'Ohabolana',
    'Mpitoriteny',
    'Tonon-kiran\'i Solomona',
    'Isaia',
    'Jeremia',
    'Fitomaniana',
    'Ezekiela',
    'Daniela',
    'Hosea',
    'Joela',
    'Amosa',
    'Obadia',
    'Jona',
    'Mika',
    'Nahoma',
    'Habakoka',
    'Zefania',
    'Hagay',
    'Zakaria',
    'Malakia',
  ];

  // New Testament books in correct biblical order (Testameta Vaovao) - from order.txt
  static const List<String> newTestamentOrder = [
    'Matio',
    'Marka',
    'Lioka',
    'Jaona',
    'Asan\'ny Apostoly',
    'Romanina',
    '1 Korintiana',
    '2 Korintiana',
    'Galatiana',
    'Efesiana',
    'Filipiana',
    'Kolosiana',
    '1 Tesalonisiana',
    '2 Tesalonisiana',
    '1 Timoty',
    '2 Timoty',
    'Titosy',
    'Filemona',
    'Hebreo',
    'Jakoba',
    '1 Petera',
    '2 Petera',
    '1 Jaona',
    '2 Jaona',
    '3 Jaona',
    'Joda',
    'Apokalypsy',
  ];

  // Mapping from file names to display names for Old Testament
  static const Map<String, String> oldTestamentFileMapping = {
    'amosa': 'Amosa',
    'daniela': 'Daniela',
    'deoteronomia': 'Deoteronomia',
    'eksodosy': 'Eksodosy',
    'estera': 'Estera',
    'ezekiela': 'Ezekiela',
    'ezra': 'Ezra',
    'fitomaniana': 'Fitomaniana',
    'genesisy': 'Genesisy',
    'habakoka': 'Habakoka',
    'hagay': 'Hagay',
    'hosea': 'Hosea',
    'isaia': 'Isaia',
    'jeremia': 'Jeremia',
    'joba': 'Joba',
    'joela': 'Joela',
    'jona': 'Jona',
    'josoa': 'Josoa',
    'levitikosy': 'Levitikosy',
    'malakia': 'Malakia',
    'mpanjaka-faharoa': '2 Mpanjaka',
    'mpanjaka-voalohany': '1 Mpanjaka',
    'mpitoriteny': 'Mpitoriteny',
    'mpitsara': 'Mpitsara',
    'nahoma': 'Nahoma',
    'nehemia': 'Nehemia',
    'nomery': 'Nomery',
    'obadia': 'Obadia',
    'ohabolana': 'Ohabolana',
    'rota': 'Rota',
    'salamo': 'Salamo',
    'samoela-faharoa': '2 Samoela',
    'samoela-voalohany': '1 Samoela',
    'tantara-faharoa': '2 Tantara',
    'tantara-voalohany': '1 Tantara',
    'tononkirani-solomona': 'Tonon-kiran\'i Solomona',
    'zakaria': 'Zakaria',
    'zefania': 'Zefania',
  };

  // Mapping from file names to display names for New Testament
  static const Map<String, String> newTestamentFileMapping = {
    '1-jaona': '1 Jaona',
    '1-korintianina': '1 Korintiana',
    '1-petera': '1 Petera',
    '1-tesalonianina': '1 Tesalonisiana',
    '1-timoty': '1 Timoty',
    '2-jaona': '2 Jaona',
    '2-korintianina': '2 Korintiana',
    '2-petera': '2 Petera',
    '2-tesalonianina': '2 Tesalonisiana',
    '2-timoty': '2 Timoty',
    '3-jaona': '3 Jaona',
    'apokalypsy': 'Apokalypsy',
    'asanny-apostoly': 'Asan\'ny Apostoly',
    'efesianina': 'Efesiana',
    'filemona': 'Filemona',
    'filipianina': 'Filipiana',
    'galatianina': 'Galatiana',
    'hebreo': 'Hebreo',
    'jakoba': 'Jakoba',
    'jaona': 'Jaona',
    'joda': 'Joda',
    'kolosianina': 'Kolosiana',
    'lioka': 'Lioka',
    'marka': 'Marka',
    'matio': 'Matio',
    'romanina': 'Romanina',
    'titosy': 'Titosy',
  };

  // Get display name for Old Testament book from file name
  static String getOldTestamentDisplayName(String fileName) {
    return oldTestamentFileMapping[fileName] ?? fileName;
  }

  // Get display name for New Testament book from file name
  static String getNewTestamentDisplayName(String fileName) {
    return newTestamentFileMapping[fileName] ?? fileName;
  }

  // Check if a book is from Old Testament
  static bool isOldTestamentBook(String bookName) {
    if (oldTestamentOrder.contains(bookName)) {
      return true;
    }
    
    // Check if English name maps to Old Testament
    final malagasyName = translateToMalagasy(bookName);
    return oldTestamentOrder.contains(malagasyName);
  }

  // Check if a book is from New Testament
  static bool isNewTestamentBook(String bookName) {
    if (newTestamentOrder.contains(bookName)) {
      return true;
    }
    
    // Check if English name maps to New Testament
    final malagasyName = translateToMalagasy(bookName);
    return newTestamentOrder.contains(malagasyName);
  }

  // Get sorted list of Old Testament books based on biblical order
  static List<String> getSortedOldTestamentBooks(List<String> availableBooks) {
    final sortedBooks = <String>[];
    
    for (final bookName in oldTestamentOrder) {
      if (availableBooks.contains(bookName)) {
        sortedBooks.add(bookName);
      }
    }
    
    // Add any available books not in standard order (append at end)
    for (final bookName in availableBooks) {
      if (oldTestamentOrder.contains(bookName) && !sortedBooks.contains(bookName)) {
        sortedBooks.add(bookName);
      }
    }
    
    return sortedBooks;
  }

  // Get sorted list of New Testament books based on biblical order
  static List<String> getSortedNewTestamentBooks(List<String> availableBooks) {
    final sortedBooks = <String>[];
    
    for (final bookName in newTestamentOrder) {
      if (availableBooks.contains(bookName)) {
        sortedBooks.add(bookName);
      }
    }
    
    // Add any available books not in standard order (append at end)
    for (final bookName in availableBooks) {
      if (newTestamentOrder.contains(bookName) && !sortedBooks.contains(bookName)) {
        sortedBooks.add(bookName);
      }
    }
    
    return sortedBooks;
  }

  // Get all books sorted by testament and biblical order
  static Map<String, List<String>> getAllBooksSortedByTestament(List<String> allBooks) {
    final oldTestamentBooks = <String>[];
    final newTestamentBooks = <String>[];
    
    for (final bookName in allBooks) {
      if (isOldTestamentBook(bookName)) {
        oldTestamentBooks.add(bookName);
      } else if (isNewTestamentBook(bookName)) {
        newTestamentBooks.add(bookName);
      }
    }
    
    return {
      'Testameta Taloha': getSortedOldTestamentBooks(oldTestamentBooks),
      'Testameta Vaovao': getSortedNewTestamentBooks(newTestamentBooks),
    };
  }

  // Translate English book name to Malagasy
  static String translateToMalagasy(String englishName) {
    return englishToMalagasyMapping[englishName] ?? englishName;
  }

  // Get biblical order position for a book (for sorting)
  static int getBookOrderPosition(String bookName) {
    // First try direct match
    final oldTestamentIndex = oldTestamentOrder.indexOf(bookName);
    if (oldTestamentIndex != -1) {
      return oldTestamentIndex;
    }
    
    final newTestamentIndex = newTestamentOrder.indexOf(bookName);
    if (newTestamentIndex != -1) {
      return oldTestamentOrder.length + newTestamentIndex; // New Testament comes after Old Testament
    }
    
    // Try translating from English to Malagasy
    final malagasyName = translateToMalagasy(bookName);
    final malagasyOldTestamentIndex = oldTestamentOrder.indexOf(malagasyName);
    if (malagasyOldTestamentIndex != -1) {
      return malagasyOldTestamentIndex;
    }
    
    final malagasyNewTestamentIndex = newTestamentOrder.indexOf(malagasyName);
    if (malagasyNewTestamentIndex != -1) {
      return oldTestamentOrder.length + malagasyNewTestamentIndex;
    }
    
    return 999; // Unknown books go to end
  }

  // Get display name for a book (translate English to Malagasy if needed)
  static String getDisplayName(String bookName) {
    // If it's already a Malagasy name, return as is
    if (oldTestamentOrder.contains(bookName) || newTestamentOrder.contains(bookName)) {
      return bookName;
    }
    
    // Otherwise, try to translate from English
    return translateToMalagasy(bookName);
  }
}