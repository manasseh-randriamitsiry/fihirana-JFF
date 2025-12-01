# GitHub Actions Secrets Setup Guide

This document provides comprehensive instructions for setting up and managing GitHub Actions secrets for the Fihirana JFF Flutter project CI/CD pipeline.

## 🚨 Required Secrets

The following secrets are required for the CI/CD pipeline to function properly:

### 1. Android Signing Secrets
- `KEYSTORE_BASE64` - Base64 encoded Android keystore file (`.jks`)
- `KEY_ALIAS` - Android key alias
- `KEY_PASSWORD` - Android key password  
- `KEY_STORE_PASSWORD` - Android keystore password

### 2. Firebase Configuration
- `GOOGLE_JSON_BASE64` - Base64 encoded `google-services.json` file

### 3. Optional Secrets
- `TOKEN` - Personal access token (if needed for additional operations)

## 📋 Setup Instructions

### Prerequisites
- Repository admin access
- Android signing keystore file
- Firebase configuration file

### Step 1: Prepare Android Signing Files

1. **Locate your Android keystore file** (usually `android/app/fihirana.jks`)
2. **Encode the keystore to base64**:
   ```bash
   # On macOS/Linux
   base64 -i android/app/fihirana.jks | tr -d '\n'
   
   # On Windows (PowerShell)
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/fihirana.jks"))
   ```

3. **Get your key information** from `android/app/build.gradle.kts` or your signing configuration:
   ```kotlin
   signingConfigs {
       release {
           keyAlias 'your-key-alias'           // This goes to KEY_ALIAS
           keyPassword 'your-key-password'     // This goes to KEY_PASSWORD
           storeFile file('fihirana.jks')      // This file gets encoded to KEYSTORE_BASE64
           storePassword 'store-password'      // This goes to KEY_STORE_PASSWORD
       }
   }
   ```

### Step 2: Prepare Firebase Configuration

1. **Download `google-services.json`** from Firebase Console
2. **Encode to base64**:
   ```bash
   # On macOS/Linux
   base64 -i google-services.json | tr -d '\n'
   
   # On Windows (PowerShell)
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json"))
   ```

### Step 3: Add Secrets to GitHub Repository

#### Method 1: Using GitHub CLI (Recommended)
```bash
# Set Android signing secrets
gh secret set KEYSTORE_BASE64 --body "<base64-encoded-keystore>"
gh secret set KEY_ALIAS --body "your-key-alias"
gh secret set KEY_PASSWORD --body "your-key-password"
gh secret set KEY_STORE_PASSWORD --body "your-store-password"

# Set Firebase configuration
gh secret set GOOGLE_JSON_BASE64 --body "<base64-encoded-google-services-json>"
```

#### Method 2: Using GitHub Web UI
1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name and value

### Step 4: Verify Configuration

1. **Check current secrets**:
   ```bash
   gh secret list
   ```

2. **Test the CI/CD pipeline**:
   - Create a pull request to trigger the `dart.yml` workflow
   - Or push to master to trigger the `release.yml` workflow

## 🔒 Security Best Practices

### Secret Management
- ✅ **Never commit secrets to version control**
- ✅ **Use strong, unique passwords for signing**
- ✅ **Rotate secrets periodically**
- ✅ **Limit secret access to necessary team members**
- ✅ **Use GitHub's built-in secret scanning**

### Access Control
- Only repository administrators should manage secrets
- Use GitHub's fine-grained permissions for team access
- Enable two-factor authentication for all admins
- Regularly audit who has access to secrets

### Backup Strategy
- Keep secure backups of your keystore file
- Store passwords in a secure password manager
- Document the secret setup process for your team
- Have a recovery plan for lost secrets

## 🚀 Workflow Usage

### CI Workflow (`dart.yml`)
The CI workflow uses these secrets:
- `GOOGLE_JSON_BASE64` - For Firebase integration
- `KEYSTORE_BASE64` - For release build verification

### Release Workflow (`release.yml`)
The release workflow uses these secrets:
- `GOOGLE_JSON_BASE64` - For Firebase integration in release builds
- `KEYSTORE_BASE64` - For signing release APKs
- `KEY_ALIAS`, `KEY_PASSWORD`, `KEY_STORE_PASSWORD` - For signing configuration

## 🔍 Troubleshooting

### Common Issues

1. **"Keystore file was not created" error**
   - Verify `KEYSTORE_BASE64` is correctly encoded
   - Check that the base64 string has no extra whitespace
   - Ensure the keystore file is valid

2. **"google-services.json not found" error**
   - Verify `GOOGLE_JSON_BASE64` is correctly encoded
   - Check Firebase project configuration
   - Ensure the JSON file is valid

3. **Build failures with signing errors**
   - Verify all signing secrets match your keystore
   - Check that `KEY_ALIAS` is correct
   - Ensure passwords are accurate

### Debug Commands
```bash
# Test base64 encoding/decoding
echo "<base64-string>" | base64 -d | file -

# Verify keystore
keytool -list -v -keystore android/app/fihirana.jks

# Check workflow runs
gh run list --limit 10
gh run view <run-id>
```

## 📚 Additional Resources

- [GitHub Actions secrets documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Android app signing guide](https://developer.android.com/studio/publish/app-signing)
- [Firebase setup guide](https://firebase.google.com/docs/android/setup)
- [GitHub CLI documentation](https://cli.github.com/manual/gh_secret)

## 🔄 Maintenance

### Regular Tasks
- [ ] Review secret access permissions quarterly
- [ ] Rotate signing passwords annually
- [ ] Update Firebase configuration as needed
- [ ] Test CI/CD pipeline after major changes

### Emergency Procedures
- If secrets are compromised:
  1. Immediately rotate all compromised secrets
  2. Revoke any exposed tokens
  3. Update GitHub repository secrets
  4. Monitor for unauthorized access
  5. Document the incident

---

**Last Updated**: 2025-12-01  
**Maintainers**: Fihirana JFF Development Team  
**Version**: 1.0