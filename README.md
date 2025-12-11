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
*   **Audio Playback**: High-quality streaming with just_audio library
*   **Audio Caching**: Local caching for offline playback with automatic cleanup
*   **Foreground Audio Service**: Background audio playback with system integration
*   **Audio File Mapping**: Intelligent audio file association with URL verification
*   **User Recordings**: Record custom hymn performances with high-quality audio capture
*   **Recording Player**: Full-featured player with speed controls and seek functionality
*   **Recording Overlay**: Persistent floating player for continuous background listening
*   **Google Drive Integration**: Seamless upload and sync recordings to Google Drive
*   **Upload Retry**: Automatic retry mechanism with progress tracking

### 👤 **User & Authentication**
*   **Google Sign-In**: Firebase-based user authentication
*   **Admin Panel**: Administrative interface for content management
*   **Biometric Authentication**: Secure local authentication options
*   **User Management**: Admin controls for managing users

### 📱 **Interface & Design**
*   **Modern UI**: Clean, responsive interface with Material Design 3 principles
*   **Dark Mode Support**: Full light/dark theme support with system detection
*   **Customizable Themes**: Personalized color themes with real-time preview
*   **Font Customization**: 20+ font families with dynamic size adjustment
*   **Neumorphic Design**: Modern neumorphic UI elements with depth effects
*   **Rive Animations**: Custom animations for loading states and interactions
*   **Liquid Swipe**: Smooth liquid swipe navigation for onboarding
*   **Curved Navigation**: Custom curved navigation bar with smooth transitions
*   **Zoom Drawer**: Advanced drawer navigation with gesture support
*   **Shimmer Effects**: Loading animations for enhanced user experience

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
*   **Daily Verse Notifications**: Scheduled daily Bible verse delivery with awesome_notifications
*   **Customizable Notifications**: User-defined notification times and preferences
*   **Inspiring Verses**: Curated collection of inspiring verses with context
*   **Rich Notifications**: Advanced notifications with actions and deep linking
*   **Update Notifications**: Automatic alert system for app updates via GitHub releases
*   **Background Sync**: Periodic data synchronization with notification alerts

### 🌐 **Localization & Languages**
*   **Multi-language Support**: English, French, and Malagasy (mg) languages
*   **Full Internationalization**: Complete i18n support with ARB files and dynamic switching
*   **RTL Support**: Right-to-left language support for future expansions
*   **Localized Content**: Language-specific hymn titles and Bible translations

### ⚙️ **App Management & Updates**
*   **Auto-Update Checking**: Automatic GitHub release monitoring with version comparison
*   **In-App Updates**: Flexible and immediate update options with in_app_update
*   **APK Download Service**: Direct APK download and installation with progress tracking
*   **Version Management**: Track installed and available versions with detailed info
*   **Background Sync**: Periodic data synchronization with conflict resolution
*   **Background Announcements**: Automatic announcement checking with expiration support
*   **Device Info Integration**: Enhanced compatibility checking and device-specific optimizations

### 🔐 **Security & Storage**
*   **Secure Storage**: Flutter secure storage for sensitive data with encryption
*   **Biometric Authentication**: Local authentication with fingerprint/face recognition
*   **File Management**: Import/export functionality with comprehensive file picker
*   **Storage Optimization**: Intelligent local storage management and automatic cleanup
*   **Permission Management**: Granular permission handling with user-friendly requests

### 🔍 **Search & Discovery**
*   **Powerful Search**: Find hymns by number, title, or content
*   **Advanced Filters**: Refine search results with multiple criteria
*   **Quick Access**: Fast navigation to frequently used content

### 🎙️ **Recording & User Content**
*   **Audio Recording**: Record custom hymn performances with high-quality audio
*   **Recording Management**: Organize, play, and manage personal recordings
*   **Cloud Upload**: Upload recordings to Google Drive for backup and sharing
*   **Recording Player**: Full-featured player with speed controls and seek functionality
*   **Background Playback**: Persistent floating player for continuous listening
*   **Upload Status**: Real-time upload progress and retry mechanisms

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

### 3. Development Tools
The project includes several utility scripts in the `tool/` directory:
*   `generate_assets.dart` - Updates asset manifests and pubspec.yaml
*   `combine_hymns.dart` - Combines individual hymn JSON files into a single file
*   `update_version.dart` - Manages app versioning across build files
*   `verify_audio_urls.dart` - Validates audio file availability and URLs

### 4. Testing
Run tests with:
```bash
flutter test
```

### 4.1 Code Quality
The project uses several tools to maintain code quality:
```bash
# Run static analysis
flutter analyze

# Check code formatting
dart format --set-exit-if-changed .

# Run all quality checks together
flutter analyze && flutter test && dart format --set-exit-if-changed .
```

### 5. Build Configuration (For Release)

#### 📱 Supported Platforms
- **Android**: Full support with auto-updates, notifications, and background services
- **iOS**: Core functionality with optimized performance
- **Web**: Basic hymn viewing and Bible reading capabilities
- **Windows**: Desktop support with full feature set
- **Linux**: Desktop support with full feature set
- **macOS**: Desktop support with optimized performance

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

## 📁 Project Structure

```
lib/
├── app/                # Application-level configuration
│   ├── theme/         # Theme and styling controllers
│   ├── constants/     # App-wide constants
│   ├── di/            # Dependency injection setup
│   ├── init/          # App initialization
│   ├── localization/  # Localization configuration
│   ├── navigation/    # Navigation setup
│   ├── security/      # Security utilities
│   └── utils/         # General utilities
├── features/          # Feature modules
│   ├── admin/         # Admin panel functionality
│   ├── announcement/  # Announcement system
│   ├── audio/         # Audio playback and management
│   ├── auth/          # Authentication services
│   ├── bible/         # Bible reading and features
│   ├── contact/       # Contact management
│   ├── daily_verse/   # Daily verse notifications
│   ├── favorites/     # Favorites management
│   ├── history/       # Viewing history
│   ├── home/          # Home screen
│   ├── hymn/          # Hymn display and management
│   ├── intro/         # App introduction/onboarding
│   ├── playlist/      # Playlist management
│   ├── recording/     # Audio recording features
│   └── settings/      # App settings
├── l10n/              # Internationalization files
├── shared/            # Shared widgets and components
├── app.dart           # Main app widget
├── firebase_options.dart # Firebase configuration
└── main.dart          # App entry point

assets/
├── animations/        # Rive animation files
├── baiboly/          # Bible data files
├── fonts/            # Custom font files (20+ font families)
├── images/           # Image assets
└── json/             # Hymn data files (800+ individual JSON files)

tool/                 # Development and maintenance scripts
```

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
4.  **Run Tests**: Ensure all tests pass and code follows project standards.
5.  **Commit & Push**:
    ```bash
    git add .
    git commit -m "Add hymn #100"
    git push origin feature/add-hymn-100
    ```
6.  **Create a Pull Request**: Go to GitHub and open a PR against the `main` branch.

---

## 🌍 Localization

To update translations or add a new language:

1.  Modify the `.arb` files in `lib/l10n/`.
2.  Run the generation command:
    ```bash
    flutter gen-l10n
    ```

---

## 🔧 Troubleshooting

### Common Issues

#### **Build Issues**
*   **Gradle errors**: Run `flutter clean && flutter pub get`
*   **Missing assets**: Run `dart tool/generate_assets.dart` to update asset manifests
*   **Font issues**: Ensure all 20+ font files are present in `assets/fonts/`
*   **Dependency conflicts**: Check Flutter version compatibility with `flutter doctor -v`

#### **Audio/Recording Issues**
*   **Permission denied**: Check microphone permissions in app settings and Android manifest
*   **Upload failures**: Verify Google Drive authentication and network connectivity
*   **Playback issues**: Ensure audio files are properly cached and available
*   **Background audio**: Check foreground service permissions on Android 8.0+

#### **Firebase Issues**
*   **Authentication errors**: Verify `google-services.json` is correctly placed in `android/app/`
*   **Firestore connection**: Check Firebase project configuration and security rules
*   **Build errors**: Ensure Firebase SDK versions are compatible across all platforms

#### **Platform-Specific Issues**
*   **iOS build**: Verify Xcode configuration and signing certificates
*   **Web limitations**: Some features like recording are not available on web platform
*   **Desktop builds**: Ensure platform-specific dependencies are properly configured

### Development Tips
*   Use `flutter run --debug` for development with hot reload
*   Check `flutter doctor` for environment setup issues
*   Monitor console logs for debugging recording and upload issues
*   Test on multiple devices and platforms for comprehensive compatibility
*   Use `flutter logs` to view real-time device logs during debugging
*   For audio issues, test with both network and cached scenarios

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📊 Project Statistics

- **Hymns**: 800+ traditional hymns with full lyrics
- **Audio Files**: Integrated audio playback for hundreds of hymns
- **Languages**: 3 languages (English, French, Malagasy)
- **Platforms**: 6 supported platforms (Android, iOS, Web, Windows, Linux, macOS)
- **Fonts**: 20+ font families for customization
- **Features**: 50+ features spanning audio, recording, social, and productivity tools

---

## 🙏 Acknowledgments

*   **Flutter Community** For the amazing framework and ecosystem
*   **Firebase Team** For providing robust backend services
*   **Contributors** Everyone who has contributed hymns, translations, and code improvements
*   **Users** The community that makes this app meaningful

---

<div>

**⭐ If this project has blessed you, consider giving it a star on GitHub! ⭐**

Made with ❤️ for the faith community

</div>