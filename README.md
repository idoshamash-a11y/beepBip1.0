# BEEPBIP - Location-Based Social Discovery App

A Flutter mobile application for location-based social discovery with Supabase backend, Google Maps integration, and real-time features.

## Features

### Authentication & Profiles
- Email/password authentication
- Social login (Google, Facebook)
- Unique serial ID generation for each user
- Two profile types:
  - **Personal Profile** (Free/Premium): Share interests, connect with people nearby
  - **Business Profile** (Premium only): Promote business, manage locations, set hours

### Privacy & Visibility
- Profile visibility toggle (Open/Closed)
- Location sharing options:
  - Don't share
  - Visible without location
  - Visible with location

### Tech Stack
- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **Maps**: Google Maps
- **State Management**: Riverpod
- **Navigation**: GoRouter

## Project Structure

```
lib/
├── core/
│   ├── config/           # Configuration files
│   ├── router/           # App routing
│   └── theme/            # App theme
├── features/
│   ├── auth/             # Authentication
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── profile/          # Profile management
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   ├── location/         # Location services
│   │   ├── models/
│   │   └── services/
│   ├── home/             # Home screen
│   └── map/              # Map features
└── main.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Supabase account
- Google Cloud account (for Maps API)
- Google Cloud Console project (for Google Sign-In)
- Facebook Developer account (for Facebook Login)

### 1. Clone the Repository
```bash
cd beepbip
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Supabase Setup

#### Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Wait for the database to be provisioned

#### Run Database Schema
1. Open Supabase SQL Editor
2. Copy and paste the contents of `database/schema.sql`
3. Execute the SQL script
4. Verify tables are created successfully

#### Configure Authentication Providers

**Email Authentication:**
- Already enabled by default

**Google OAuth:**
1. Go to Authentication > Providers > Google
2. Enable Google provider
3. Add your Google OAuth credentials (see Google Setup section below)

**Facebook OAuth:**
1. Go to Authentication > Providers > Facebook
2. Enable Facebook provider
3. Add your Facebook App ID and Secret (see Facebook Setup section below)

#### Get Supabase Credentials
1. Go to Project Settings > API
2. Copy the following:
   - Project URL
   - Anon/Public Key

### 4. Google Setup

#### Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. Create an API key
5. Restrict the API key to your app

#### Google Sign-In
1. In the same Google Cloud project
2. Go to APIs & Services > Credentials
3. Create OAuth 2.0 Client IDs for:
   - Android (get SHA-1 from your app)
   - iOS (get bundle ID from your app)
   - Web (for Supabase)
4. Copy the client IDs

### 5. Facebook Setup
1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create a new app
3. Add Facebook Login product
4. Configure OAuth redirect URIs (get from Supabase)
5. Copy App ID and App Secret

### 6. Configure the App

Edit `lib/core/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
}
```

### 7. Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <application>
        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

        <!-- Facebook App ID -->
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id"/>
    </application>

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
</manifest>
```

Edit `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
</resources>
```

### 8. Configure iOS

Edit `ios/Runner/AppDelegate.swift` for Google Sign-In:
```swift
import GoogleSignIn

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}
```

Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Google OAuth -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
            <!-- Facebook -->
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>

<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookDisplayName</key>
<string>BEEPBIP</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby people and places</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show nearby people and places</string>
```

### 9. Run the App

```bash
# Run on Android
flutter run

# Run on iOS
flutter run

# Build for release
flutter build apk        # Android
flutter build ios        # iOS
```

## Database Schema

The app uses the following main tables:
- `users` - User accounts with serial IDs
- `profiles` - Base profile settings
- `personal_profiles` - Personal profile details
- `business_profiles` - Business profile details
- `business_hours` - Business operating hours
- `locations` - Profile locations

See `database/schema.sql` for complete schema with Row Level Security policies.

## Features Implementation Status

- [x] Project structure setup
- [x] Database schema design
- [x] Authentication (email/password + social)
- [x] Unique serial ID generation
- [x] Profile type selection
- [x] Personal profile setup
- [x] Business profile setup
- [x] Visibility and location settings
- [ ] Google Maps integration (UI ready, needs implementation)
- [ ] Real-time features (WebSocket/Supabase real-time)
- [ ] Image upload to Supabase Storage
- [ ] Nearby profiles discovery
- [ ] Profile editing
- [ ] Business hours management UI
- [ ] Multiple locations for businesses
- [ ] In-app notifications
- [ ] Premium subscription flow

## Next Steps

1. **Complete Google Maps Integration**
   - Implement map view with user markers
   - Add location picker for profile setup
   - Show nearby profiles on map

2. **Image Upload**
   - Configure Supabase Storage
   - Implement image upload for profile photos/logos
   - Add image compression

3. **Real-time Features**
   - Set up Supabase real-time subscriptions
   - Live updates for nearby profiles
   - Real-time location updates (if enabled)

4. **Premium Features**
   - Stripe/payment integration
   - Premium tier benefits
   - Subscription management

5. **Additional Features**
   - Chat/messaging
   - Profile views tracking
   - Search and filters
   - Notifications system

## Contributing

This is a private project. For questions or issues, please contact the development team.

## License

Proprietary - All rights reserved
