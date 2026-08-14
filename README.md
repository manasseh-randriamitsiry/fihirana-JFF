# 🎵 Fihirana Jesosy Famonjena Fahamarinantsika

Just a hymn  app

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate code (build_runner):**
    ```bash
    flutter pub run build_runner build
    ```
    *This generates optimized JSON serialization code for data models using `json_serializable`.*

3.  **Run the app:**
    ```bash
    flutter run
    ```

### 3. Development Tools

#### 📦 **Code Generation**
*   **build_runner**: Generates optimized JSON serialization code
    ```bash
    flutter gen-l10n
    # Generate code for all annotated models
    flutter pub run build_runner build

    # Watch mode for continuous generation during development
    flutter pub run build_runner watch
    ```

### 4. Testing
Run tests with:
```bash
flutter test
```