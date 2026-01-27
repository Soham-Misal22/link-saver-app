# Link Saver App

A Flutter application for organizing and saving links from social media with AI-powered folder suggestions.

## Features

- 📱 **Share from Any App**: Save links directly from Instagram, YouTube, Twitter, Chrome, and more
- 🤖 **AI Folder Suggestions**: Intelligent folder recommendations powered by Google's Gemini AI
- 📁 **Smart Organization**: Create and manage custom folders for your links
- 🔐 **Secure Authentication**: Google Sign-In powered by Clerk
- ☁️ **Cloud Sync**: All data synced via Supabase
- 🎨 **Modern UI**: Beautiful Material Design interface

## Prerequisites

- Flutter SDK 3.9.0 or higher
- Android Studio / VS Code
- Firebase project
- Clerk account
- Supabase project
- Google Cloud project (for Gemini AI)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd link_saver_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

### 4. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android app to your Firebase project
3. Download `google-services.json` and place in `android/app/`
4. Update `android/app/build.gradle.kts` with your Firebase configuration

### 5. Clerk Setup

1. Create a Clerk application at https://dashboard.clerk.com
2. Enable Google OAuth provider
3. Configure Google OAuth settings:
   - Enable "Always show selector prompt" for account picker
4. Get your Clerk Frontend API key
5. Update the Clerk configuration in the app (see `CLERK_SETUP.md` for details)

### 6. Supabase Setup

1. Create a Supabase project at https://supabase.com
2. Run the database migrations from `supabase/` directory
3. Set up Row Level Security (RLS) policies
4. Get your project URL and service role key
5. Add them to `.env` file

### 7. Google Cloud / Gemini AI Setup

1. Create a Google Cloud project
2. Enable Gemini AI API
3. Create API key
4. Configure the API key in your Supabase Edge Functions

### 8. Update Package Name

**IMPORTANT**: Before publishing, change the package name from `com.example.link_saver_app`:

1. Update `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.yourdomain.linksaver"
   namespace = "com.yourdomain.linksaver"
   ```

2. Update `AndroidManifest.xml` if needed

3. Rename Kotlin package directories to match

## Building for Production

### Generate Release APK

```bash
flutter build apk --release
```

### Generate App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

### Create Signing Keystore

Before building for release, create a keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties`:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
```

Update `android/app/build.gradle.kts` to use the keystore.

## Project Structure

```
lib/
├── main.dart                 # Main app entry point
├── services/
│   ├── metadata_service.dart # URL metadata fetching
│   └── suggestion_service.dart # AI folder suggestions
└── ...
```

## Key Technologies

- **Flutter**: Cross-platform mobile framework
- **Clerk**: Authentication and user management
- **Supabase**: PostgreSQL database and backend
- **Firebase**: App infrastructure
- **Gemini AI**: Intelligent folder suggestions
- **Material Design**: UI components

## Play Store Publication

See `implementation_plan.md` for a comprehensive checklist of requirements before publishing to Play Store.

### Critical Steps:

1. ✅ Update package name from `com.example.*`
2. ✅ Create privacy policy and host online
3. ✅ Generate release signing key
4. ✅ Complete Data Safety form in Play Console
5. ✅ Prepare store assets (screenshots, feature graphic)
6. ✅ Test on multiple devices and Android versions

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Yes |

## Security Notes

- **Never commit `.env` file to version control**
- Store API keys securely
- Rotate keys if exposed
- Use environment-specific configurations for dev/staging/prod

## Testing

```bash
# Run tests
flutter test

# Run on device
flutter run

# Run in release mode
flutter run --release
```

## Troubleshooting

### Build Errors
- Run `flutter clean` and `flutter pub get`
- Check Flutter and Dart SDK versions
- Verify all dependencies are installed

### Share Functionality Not Working
- Verify `ShareReceiverActivity` is properly configured in `AndroidManifest.xml`
- Check that SEND intent filter is present
- Test on physical device (not emulator)

### Authentication Issues
- Verify Clerk configuration
- Check Firebase setup
- Ensure Google OAuth is enabled in Clerk Dashboard

## License

[Your License Here]

## Support

For support, email: [your-support-email]

## Contributing

[Contributing guidelines if applicable]
