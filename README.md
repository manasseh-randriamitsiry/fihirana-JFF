# 🎵 Fihirana Jesosy Famonjena Fahamarinantsika

A comprehensive digital Hymnal and Bible application designed to bring spiritual resources to your fingertips. This app combines traditional hymns with modern features like audio playback, favorites, and a built-in Bible.

### Developer
**👨‍💻** Manasseh Randriamitsiry — [manassehrandriamitsiry@gmail.com](mailto:manassehrandriamitsiry@gmail.com)

---

## ✨ Features

*   **📖 Complete Hymnal**: Access to a vast collection of hymns with lyrics.
*   **🎧 Audio Playback**: Listen to hymn tunes (requires internet connection).
*   **✝️ Built-in Bible**: Read the Bible directly within the app.
*   **❤️ Favorites**: Save your favorite hymns for quick access.
*   **🔍 Search**: Powerful search functionality for finding hymns by number or title.
*   **🎨 Modern UI**: Clean, user-friendly interface with dark mode support.
*   **⚙️ Customization**: Adjust font sizes and settings for a comfortable reading experience.
*   **🌈 Themes**: Support for Light and Dark modes with customizable color themes.
*   **🅰️ Fonts**: Choose from a variety of fonts and adjust text size for optimal readability.
*   **📂 Smart Playlists**: Create, manage, and share playlists with deep linking support.
*   **☁️ Cloud Sync**: Automatically syncs playlists across devices with smart merging to prevent duplicates.

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