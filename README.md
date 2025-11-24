# 🎵 Fihirana Jesosy Famonjena Fahamarinantsika

A comprehensive digital Hymnal and Bible application designed to bring spiritual resources to your fingertips. This app combines traditional hymns with modern features like audio playback, favorites, and a built-in Bible.

### Developer
**👨‍💻** Manasseh Randriamitsiry — [manassehrandriamitsiry@gmail.com](mailto:manassehrandriamitsiry@gmail.com)

---

## ✨ Features

### 📖 **Content & Reading**
*   **Complete Hymnal**: Access to a vast collection of hymns with lyrics
*   **Built-in Bible**: Full Bible text with advanced reading features
*   **Bible Highlights**: Highlight and save Bible verses with custom colors
*   **Bible Notes**: Add personal notes to Bible passages
*   **Bible Search**: Advanced search functionality within Bible text
*   **User-Generated Content**: Create custom hymns and edit existing ones
*   **Firebase Hymns**: Cloud-based hymn storage and synchronization

### 🎵 **Audio & Multimedia**
*   **Audio Playback**: Listen to hymn tunes with streaming support
*   **Audio Caching**: Local caching for offline playback
*   **Foreground Audio Service**: Background audio playback
*   **Audio File Mapping**: Intelligent audio file association

### 👤 **User & Authentication**
*   **Google Sign-In**: Firebase-based user authentication
*   **Admin Panel**: Administrative interface for content management
*   **Biometric Authentication**: Secure local authentication options
*   **User Management**: Admin controls for managing users

### 📱 **Interface & Design**
*   **Modern UI**: Clean, user-friendly interface with multiple design systems
*   **Dark Mode Support**: Full light/dark theme support
*   **Customizable Themes**: Personalized color themes and settings
*   **Font Customization**: Multiple font options with size adjustment
*   **Neumorphic Design**: Modern neumorphic UI elements
*   **Rive Animations**: Custom animations for enhanced UX
*   **Liquid Swipe**: Smooth liquid swipe navigation effects
*   **Curved Navigation**: Custom curved navigation bar
*   **Zoom Drawer**: Advanced drawer navigation system

### 🔗 **Social & Sharing**
*   **Smart Playlists**: Create, manage, and share playlists
*   **Deep Link Support**: Custom URL scheme (fihirana://) for content sharing
*   **App Links Integration**: Handle external app links seamlessly
*   **Public Notes Sharing**: Share notes with other users
*   **Community Highlights**: See public Bible highlights from the community
*   **Announcements System**: Admin announcements with expiration dates

### 📚 **History & Tracking**
*   **Viewing History**: Track recently viewed hymns and Bible passages
*   **Selection Mode**: Bulk operations on history items
*   **Favorites System**: Save and organize favorite content

### 🔔 **Notifications & Daily Content**
*   **Daily Verse Notifications**: Scheduled daily Bible verse delivery
*   **Customizable Notifications**: User-defined notification times
*   **Inspiring Verses**: Curated collection of inspiring verses
*   **Rich Notifications**: Advanced notifications with actions
*   **Update Notifications**: Alert users about app updates

### 🌐 **Localization & Languages**
*   **Multi-language Support**: English, French, and Malagasy (mg) languages
*   **Full Internationalization**: Complete i18n support with ARB files

### ⚙️ **App Management & Updates**
*   **Auto-Update Checking**: Automatic GitHub release monitoring
*   **In-App Updates**: Flexible and immediate update options
*   **APK Download Service**: Direct APK download and installation
*   **Version Management**: Track installed and available versions
*   **Background Sync**: Periodic data synchronization
*   **Background Announcements**: Automatic announcement checking

### 🔐 **Security & Storage**
*   **Secure Storage**: Flutter secure storage for sensitive data
*   **File Management**: Import/export functionality with file picker
*   **Storage Optimization**: Local storage management and cleanup

### 🔍 **Search & Discovery**
*   **Powerful Search**: Find hymns by number, title, or content
*   **Advanced Filters**: Refine search results with multiple criteria
*   **Quick Access**: Fast navigation to frequently used content

---

## 🚀 Setup Instructions

### 1. Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
*   Android Studio or VS Code with Flutter extensions.

### 2. Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/manasseh-randriamitsiry/fihirana-JFF.git
    cd fihirana-JFF
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

### 3. Build Configuration (For Release)

#### 🔹 Google Services Configuration
1.  Copy the `google-services.json` file from your Firebase project into:
    ```
    android/app/google-services.json
    ```
2.  Convert it to Base64 (for CI/CD):
    ```bash
    python -c "import base64; print(base64.b64encode(open('android/app/google-services.json','rb').read()).decode())"
    ```
3.  Add it as a **GitHub secret** named `GOOGLE_JSON_BASE64`.

#### 🔹 Keystore File Configuration
1.  Convert your keystore (`.jks`) file to Base64:
    ```bash
    python -c "import base64; print(base64.b64encode(open('your_keystore.jks','rb').read()).decode())"
    ```
2.  Add it to GitHub Secrets as `KEYSTORE_BASE64`.

---

## 🤝 Contribution Guide

We welcome contributions! Whether you want to add new hymns, fix typos, or improve the code, here is how you can help.

### 📝 How to Add a New Hymn (Text)

Hymns are stored as individual JSON files in the `assets/json/` directory.

1.  **Create a new JSON file**:
    *   Navigate to `assets/json/`.
    *   Create a file named `{number}-{TITLE-SLUG}.json` (e.g., `100-ANARAM-BAOVAO.json`).

2.  **Format the JSON**:
    Use the following structure:
    ```json
    {
      "number": "100",
      "title": "ANARAM-BAOVAO",
      "verses": {
        "1": "Verse 1 lyrics here...",
        "2": "Verse 2 lyrics here..."
      },
      "chorus": "Chorus lyrics here (optional)"
    }
    ```

3.  **Register the new asset**:
    Run the asset generation script to update the manifest:
    ```bash
    dart tool/generate_assets.dart
    ```
    *This script updates `assets/hymn_manifest.json` and ensures the new file is included in `pubspec.yaml`.*

### 🎵 How to Add Audio

Audio files are hosted in a separate repository to keep the app size light.

1.  **Prepare the Audio File**:
    *   Format: `MP3`.
    *   Naming Convention: `{number}.mp3` (e.g., `1.mp3` for Hymn #1).

2.  **Submit the Audio**:
    *   Go to the [Fihirana-audio repository](https://github.com/manasseh-randriamitsiry/Fihirana-audio).
    *   Fork the repository.
    *   Upload your `.mp3` file.
    *   Create a Pull Request.

    *Note: The app automatically fetches the list of available audio files from this repository.*

### 🌿 Branching & Pull Requests

If you are contributing code or data changes to this repository:

1.  **Fork & Clone**: Fork the project to your GitHub account and clone it locally.
2.  **Create a Branch**:
    ```bash
    git checkout -b feature/add-hymn-100
    # or
    git checkout -b fix/typo-hymn-5
    ```
3.  **Make Changes**: Add your files or code changes.
4.  **Commit & Push**:
    ```bash
    git add .
    git commit -m "Add hymn #100"
    git push origin feature/add-hymn-100
    ```
5.  **Create a Pull Request**: Go to GitHub and open a PR against the `master` branch.

---

## 🌍 Localization

To update translations or add a new language:

1.  Modify the `.arb` files in `lib/l10n/`.
2.  Run the generation command:
    ```bash
    flutter gen-l10n
    ```
.