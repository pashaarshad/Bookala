# Bulk SMS Sender

A Flutter app for sending bulk SMS messages to multiple contacts. Store phone numbers locally on your device and send the same message to all contacts with one tap!

## ✨ Features

- 📱 **Add & Store Phone Numbers** - Save unlimited contacts in local storage
- 💾 **Local Storage** - All contacts are saved on your phone using SharedPreferences
- 📨 **Bulk SMS** - Send one message to all saved contacts at once
- ✏️ **Message Box** - Write your message once and send to everyone
- 🗑️ **Manage Contacts** - Easy add/delete functionality
- 📊 **Contact Count** - See how many contacts you have saved
- 🎨 **Clean UI** - Simple and intuitive interface

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed (3.0.0 or higher)
- Android device or emulator (SMS features only work on Android)

### Installation

1. Install dependencies:
```bash
C:\src\flutter\bin\flutter.bat pub get
```

2. Run on Android device:
```bash
C:\src\flutter\bin\flutter.bat run -d android
```

**Note:** SMS functionality requires a real Android device with SMS capabilities.

## 📱 How to Use

### Adding Contacts
1. Open the app and go to **Contacts** tab
2. Tap the **+** (plus) button at the bottom right
3. Enter the phone number (include country code like +1234567890)
4. Tap **Add**
5. Contact is saved to local storage automatically!

### Sending Bulk SMS
1. Go to **Send SMS** tab
2. See all your saved contacts listed
3. Type your message in the text box (max 160 characters)
4. Tap **Send to All Contacts**
5. Your default SMS app will open with all recipients ready to send!

## 🔒 Permissions

The app requires these Android permissions:
- `SEND_SMS` - To send SMS messages
- `READ_PHONE_STATE` - To access phone functionality

## 📁 Project Structure
```
lib/
  ├── main.dart                # App entry point
  └── screens/
      └── home_screen.dart     # Main screen with contacts & SMS pages
```

## 🛠️ Technologies Used
- **Flutter** - Cross-platform framework
- **SharedPreferences** - Local data storage
- **flutter_sms** - SMS sending functionality
- **Material Design 3** - Modern UI components

## ⚠️ Important Notes
- SMS features only work on **Android devices**
- Web/Chrome version won't have SMS functionality
- Contacts are stored locally and not synced to cloud
- Message length limited to 160 characters (standard SMS)

## 📲 Build for Release

```bash
C:\src\flutter\bin\flutter.bat build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`
