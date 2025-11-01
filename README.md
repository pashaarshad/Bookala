# Bookala

A Flutter application for booking management that works on both Android and iOS.

## Getting Started

### Prerequisites
- Flutter SDK installed (3.0.0 or higher)
- Android Studio or Xcode for running the app
- A device or emulator

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

### For Android
```bash
flutter run -d android
```

### For iOS
```bash
flutter run -d ios
```

## Features
- Cross-platform support (Android & iOS)
- Material Design 3
- Bottom navigation
- Bookings management
- Search functionality
- User profile

## Project Structure
```
lib/
  ├── main.dart           # Entry point
  ├── screens/            # App screens
  ├── models/             # Data models
  ├── services/           # API services
  └── widgets/            # Reusable widgets
```

## Build for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```
