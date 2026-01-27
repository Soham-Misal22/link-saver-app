# Deployment Guide for Play Store Publisher

## Quick Start Checklist

Before publishing to Google Play Store, complete these mandatory tasks:

### 1. Update Package Name (CRITICAL - Cannot Change After First Publish!)

**Current**: `com.example.link_saver_app`  
**Required**: Change to your own domain

**Files to update**:
- `android/app/build.gradle.kts` (lines 12, 27)
  ```kotlin
  namespace = "com.yourdomain.linksaver"
  applicationId = "com.yourdomain.linksaver"
  ```

### 2. Set Up Environment Variables

Copy `.env.example` to `.env` and fill in:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

Get these from:
- Supabase Dashboard → Settings → API
- **NEVER commit `.env` to git** (already in `.gitignore`)

### 3. Create Release Signing Key

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties`:
```properties
storePassword=your_chosen_password
keyPassword=your_chosen_password  
keyAlias=upload
storeFile=../upload-keystore.jks
```

Update `android/app/build.gradle.kts` - replace line 42:
```kotlin
release {
    signingConfig = signingConfigs.release  // Change from debug
    isMinifyEnabled = true
    isShrinkResources = true
}
```

Add this before `android` block:
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

### 4. Create Privacy Policy (MANDATORY)

**Required by Play Store** for apps with internet access.

Must include:
- Data collected (links, folders, user info via Clerk)
- How data is used (stored in Supabase)
- Third-party services (Clerk, Supabase, Firebase, Google Fonts, Gemini AI)
- User rights (data deletion, access)

Host online (GitHub Pages, your website, etc.) and add URL to Play Console.

Template generators:
- https://www.freeprivacypolicy.com/
- https://www.termsfeed.com/privacy-policy-generator/

### 5. Remove/Justify QUERY_ALL_PACKAGES Permission

In `AndroidManifest.xml`, line 4:

**Option A (Recommended)**: Remove it
```xml
<!-- Delete this line -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

**Option B**: Justify in Play Console if needed for specific URL launcher functionality.

### 6. Build Release AAB

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload this `.aab` file to Play Console (NOT `.apk`).

### 7. Prepare Store Assets

Required:
- [ ] App Icon: 512x512px (already have `app_logo.png`)
- [ ] Feature Graphic: 1024x500px (create this)
- [ ] Screenshots: Minimum 2 phone screenshots
  - Take from running app on device
  - Use `adb shell screencap` or screen recording
- [ ] Short Description: Max 80 characters
  - Example: "Save & organize links with AI-powered folder suggestions"
- [ ] Full Description: Max 4000 characters
  - See README for app features

### 8. Play Console Setup

1. Create app at https://play.google.com/console
2. Upload AAB file
3. Complete **Data Safety Form**:
   - Data types collected: Account info, User content (links/folders)
   - Data sharing: None (kept in Supabase)
   - Encryption: In transit (HTTPS)
   - Data deletion: Via account deletion
4. Complete **Content Rating** questionnaire
   - Expected rating: Everyone or Teen
5. Add store listing assets
6. Set pricing: Free
7. Select countries
8. Submit for review

### 9. Testing Checklist

Before submitting to Play Store:
- [ ] Share functionality works from Instagram, Twitter, Chrome, YouTube
- [ ] Authentication (sign in/out) works
- [ ] Folder creation/deletion works
- [ ] Link saving and retrieval works
- [ ] App doesn't crash on network loss
- [ ] Test on Android 5.0 (minSdk 21) and latest Android
- [ ] Test on different screen sizes

### 10. Post-Publish Monitoring

Set up (recommended):
- Firebase Crashlytics for crash reporting
- Analytics to track user engagement
- Monitor Play Console reviews
- Plan for regular updates

## Common Issues & Solutions

### Build Fails
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter build appbundle --release
```

### Signing Errors
- Verify `key.properties` path is correct
- Ensure keystore file exists
- Check passwords are correct

### Play Console Rejection
- Most common: Missing privacy policy
- Second: Permissions not justified (QUERY_ALL_PACKAGES)
- Third: Package name issues

## Environment-Specific Configuration

### Development
```bash
flutter run --debug
```

### Staging (if needed)
Create separate `.env.staging` with staging Supabase project

### Production
```bash
flutter build appbundle --release
```

## Important Notes

1. **Package Name**: Must be unique, cannot change after first publish
2. **Keystore**: Store securely, losing it means you cannot update the app
3. **API Keys**: Never commit to git, keep `.env` local only
4. **Target SDK**: Play Store requires targetSdk 33+ (currently using Flutter's default)
5. **App Bundle**: Always upload `.aab` not `.apk` to Play Store

## Timeline Expectations

- Initial review: 3-7 days
- After fixing issues: 1-3 days  
- Updates (after published): < 24 hours

## Support Resources

- Play Console Help: https://support.google.com/googleplay/android-developer
- Flutter Deployment: https://docs.flutter.dev/deployment/android
- App Signing: https://developer.android.com/studio/publish/app-signing

## Final Checklist

Before clicking "Submit for Review":
- [ ] Package name changed from `com.example.*`
- [ ] Release keystore created and configured
- [ ] Privacy policy created and URL added
- [ ] QUERY_ALL_PACKAGES removed or justified
- [ ] Environment variables configured
- [ ] Release AAB built successfully
- [ ] Screenshots and feature graphic prepared
- [ ] Store listing text written
- [ ] Data Safety form completed
- [ ] Content rating completed
- [ ] App tested on multiple devices
- [ ] Verified sharing works from social media apps

## Contact Publisher Support

If issues arise during setup or publication, the person publishing should:
1. Check Play Console error messages (usually very specific)
2. Review Play Policy: https://play.google.com/about/developer-content-policy/  
3. Contact developer for technical questions about the codebase

---

**Good luck with publication! 🚀**
