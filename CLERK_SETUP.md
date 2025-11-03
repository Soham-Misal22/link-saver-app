# Clerk Setup Guide for Link Saver App

## 1. Create a Clerk Account and Application

1. Go to [https://clerk.com](https://clerk.com) and sign up for an account
2. Create a new application
3. Choose "Flutter" as your framework
4. Note down your **Publishable Key** (starts with `pk_test_` or `pk_live_`)

## 2. Configure Google OAuth

1. In your Clerk dashboard, go to "Authentication" → "Social Connections"
2. Enable Google OAuth
3. You'll need to:
   - Create a Google Cloud Console project
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add your Clerk redirect URLs to the Google OAuth configuration

## 3. Update Your Flutter App

Replace the placeholder publishable key in `lib/main.dart`:

```dart
await Clerk.initialize(
  publishableKey: 'pk_test_YOUR_ACTUAL_CLERK_PUBLISHABLE_KEY', // Replace with your actual key
);
```

## 4. Database Migration

Since we've removed Supabase, you'll need to:

1. **Choose a new database solution** (Firebase Firestore, AWS DynamoDB, MongoDB, etc.)
2. **Create API endpoints** to handle:
   - Creating folders
   - Fetching folders for a user
   - Saving links to folders
   - Deleting folders and links
3. **Update the placeholder methods** in the code with actual API calls

## 5. Environment Variables

For production, consider using environment variables:

```dart
// Create a .env file or use flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

await Clerk.initialize(
  publishableKey: dotenv.env['CLERK_PUBLISHABLE_KEY']!,
);
```

## 6. Testing

1. Run `flutter pub get` to install the new dependencies
2. Update the publishable key in `main.dart`
3. Test the Google sign-in flow
4. Implement your chosen database solution
5. Replace the placeholder database calls with actual API calls

## 7. Important Notes

- The current code has placeholder database operations
- You'll need to implement actual API calls to replace the Supabase calls
- Make sure to handle authentication state properly
- Test the OAuth flow thoroughly before deploying

## 8. Next Steps

1. Set up your Clerk account and get your publishable key
2. Configure Google OAuth in Clerk dashboard
3. Choose and set up your new database solution
4. Implement the API endpoints for your database operations
5. Update the placeholder methods in the Flutter code
6. Test the complete authentication and data flow
