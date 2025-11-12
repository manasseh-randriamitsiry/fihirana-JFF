# 🎵 Fihirana Jesosy Famonjena Fahamarinantsika

### Developer  
**👨‍💻** Manasseh Randriamitsiry — [manassehrandriamitsiry@gmail.com](mailto:manassehrandriamitsiry@gmail.com)

---

## 🚀 Setup Instructions

### 1. Generate Required Files

#### 🔹 Google Services Configuration

1. Copy the `google-services.json` file from your Firebase project into:  
   ```
   android/app/google-services.json
   ```

2. Convert it to Base64:
   ```bash
   python -c "import base64; print(base64.b64encode(open('android/app/google-services.json','rb').read()).decode())"
   ```

3. Copy the Base64 output and add it as a **GitHub secret**:  
   - Go to your repository:  
     **Settings → Secrets and Variables → Actions → New repository secret**
   - Name the secret:  
     ```
     GOOGLE_JSON_BASE64
     ```
   - Paste the Base64 string as the value.

---

#### 🔹 Keystore File Configuration

1. Convert your keystore (`.jks`) file to Base64 the same way:
   ```bash
   python -c "import base64; print(base64.b64encode(open('your_keystore.jks','rb').read()).decode())"
   ```

2. Add it to GitHub Secrets as:
   ```
   KEYSTORE_BASE64
   ```

3. (Optional) You can find your **debug keystore** path and info with:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

---

## 🏷️ Release Process

Every time you push a new **Git tag**, the CI/CD pipeline automatically triggers a release build.

```bash
git tag v1.0.5
git push origin v1.0.5
```

> ✅ The CI/CD build succeeds in **release mode** only if the Firebase JSON and keystore files are correctly configured via secrets.
