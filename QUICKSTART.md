# BEEPBIP Quick Start Guide

Get up and running with BEEPBIP in 10 minutes!

## Prerequisites Checklist

- [ ] Flutter SDK installed (run `flutter doctor`)
- [ ] Supabase account created
- [ ] Google Cloud account (for Maps)
- [ ] Text editor/IDE (VS Code, Android Studio, etc.)

## Fast Setup (Development Mode)

### Step 1: Install Dependencies (2 min)

```bash
cd beepbip
flutter pub get
```

### Step 2: Supabase Setup (3 min)

1. **Create Project**: Go to [supabase.com](https://supabase.com) → New Project
   - Name: `beepbip-dev`
   - Choose a strong database password
   - Select region
   - Wait ~2 minutes for provisioning

2. **Run Database Script**:
   - Open SQL Editor in Supabase dashboard
   - Copy entire contents of `database/schema.sql`
   - Paste and click "Run"

3. **Get Credentials**:
   - Go to Settings → API
   - Copy:
     - **Project URL** (looks like: `https://xxxxx.supabase.co`)
     - **Anon public key** (long string starting with `eyJ...`)

### Step 3: Configure App (2 min)

Edit `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://xxxxx.supabase.co';  // Paste your URL
  static const String supabaseAnonKey = 'eyJ...';  // Paste your anon key

  // Leave these for now - social login can be configured later
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
}
```

### Step 4: Run the App! (3 min)

```bash
# Make sure you have a device/simulator running
flutter devices

# Run the app
flutter run
```

That's it! You should see the BEEPBIP splash screen.

## First Run Experience

1. **Splash Screen** → Auto-redirects to Login
2. **Create Account**:
   - Click "Sign Up"
   - Enter email and password
   - Click "Sign Up"
3. **Choose Profile Type**:
   - Select "Personal Profile" (or "Business Profile")
   - Click "Continue"
4. **Setup Profile**:
   - Fill in your name (required)
   - Add interests (optional)
   - Set privacy preferences
   - Click "Complete Setup"
5. **Home Screen** → You're in!

## Testing Without Social Login

For initial testing, you can use email/password authentication. Social login (Google/Facebook) can be configured later following the detailed setup in `README.md`.

## Common Issues

### Issue: Build fails with dependency errors

```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Failed to connect to Supabase"

- Double-check your Supabase URL and anon key in `supabase_config.dart`
- Make sure there are no extra spaces
- Ensure database schema was run successfully

### Issue: "Serial ID generation failed"

- Open Supabase SQL Editor
- Run: `SELECT * FROM users;`
- If empty, the trigger might not have fired
- Try creating an account again

### Issue: Android build fails

```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Issue: iOS build fails

```bash
cd ios
pod install
cd ..
flutter run
```

## Quick Feature Test

### Test Profile Creation

1. Create account with email/password
2. Choose Personal Profile
3. Fill in details and submit
4. Verify you see the home screen with your serial ID

### Test Profile Visibility

1. Go to Profile tab
2. Note your Serial ID (format: `BP-XXXXXX`)
3. Try changing visibility settings (will need to implement settings screen)

### Verify Database

1. Open Supabase Table Editor
2. Check `users` table - should see your user with serial ID
3. Check `profiles` table - should see your profile
4. Check `personal_profiles` - should see your details

## Next Steps

Once basic app is running:

1. **Add Google Maps** (see README.md → Google Setup)
2. **Configure Social Login** (see README.md → Google/Facebook Setup)
3. **Add Image Upload** (configure Supabase Storage)
4. **Test Location Features** (requires device with GPS)

## Development Tips

### Hot Reload
- Press `r` in terminal while app is running
- Most UI changes appear instantly

### Debug Mode
```bash
# Run with verbose logging
flutter run -v

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Database Changes
- Update `database/schema.sql`
- Run new SQL in Supabase SQL Editor
- Changes take effect immediately

### Clear App Data
```bash
# Android
adb shell pm clear com.example.beepbip

# iOS - delete app from simulator and reinstall
```

## Project Structure Quick Reference

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── config/
│   │   └── supabase_config.dart # ← EDIT THIS FIRST
│   ├── router/
│   │   └── app_router.dart      # Navigation routes
│   └── theme/
│       └── app_theme.dart       # App colors/styles
├── features/
│   ├── auth/                    # Login, signup, etc.
│   ├── profile/                 # Profile management
│   ├── location/                # Location services
│   ├── home/                    # Main home screen
│   └── map/                     # Map view (to be implemented)
```

## Helpful Commands

```bash
# Check Flutter setup
flutter doctor

# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Build APK (Android)
flutter build apk

# Clean build
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

## Getting Help

- **Setup Issues**: Check `README.md` for detailed instructions
- **Database Issues**: See `database/README.md`
- **Flutter Errors**: Run `flutter doctor` to diagnose

## Ready to Build?

Now that the basic app is running:
- Explore the code structure
- Customize the UI theme in `app_theme.dart`
- Add your business logic
- Implement map features
- Build something amazing!

Happy coding! 🚀
