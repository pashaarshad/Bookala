# Install Android SDK Without Android Studio

## Method 1: Download Command Line Tools Only

### Step 1: Download
Go to: https://developer.android.com/studio#command-tools
- Scroll down to "Command line tools only"
- Download: **commandlinetools-win-XXXXX_latest.zip** (Windows version)

### Step 2: Extract & Setup Directory Structure
```powershell
# Create Android SDK directory
New-Item -ItemType Directory -Path "C:\Android\Sdk" -Force

# Extract the downloaded zip to a temp location
# Then move the 'cmdline-tools' folder to:
# C:\Android\Sdk\cmdline-tools\latest\
```

**Important:** The structure should be:
```
C:\Android\Sdk\
  └── cmdline-tools\
      └── latest\
          ├── bin\
          ├── lib\
          └── ...
```

### Step 3: Add to PATH
```powershell
# Add to system PATH (run as Administrator or add via System Properties)
$env:Path += ";C:\Android\Sdk\cmdline-tools\latest\bin"
$env:Path += ";C:\Android\Sdk\platform-tools"

# Set ANDROID_HOME environment variable
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Android\Sdk', 'User')
```

### Step 4: Install SDK Components Using sdkmanager
```powershell
# Open new PowerShell window and run:
cd C:\Android\Sdk\cmdline-tools\latest\bin

# Accept licenses
.\sdkmanager.bat --licenses

# Install required components
.\sdkmanager.bat "platform-tools"
.\sdkmanager.bat "platforms;android-33"
.\sdkmanager.bat "build-tools;33.0.2"
.\sdkmanager.bat "cmdline-tools;latest"
```

### Step 5: Configure Flutter
```powershell
# Tell Flutter where Android SDK is
C:\src\flutter\bin\flutter.bat config --android-sdk "C:\Android\Sdk"

# Verify
C:\src\flutter\bin\flutter.bat doctor -v
```

### Step 6: Build APK
```powershell
cd C:\Users\Admin\Desktop\CodePlay\Bookala
C:\src\flutter\bin\flutter.bat build apk --release
```

---

## Method 2: Using Chocolatey (Easiest!)

If you have Chocolatey package manager:
```powershell
# Install Android SDK
choco install android-sdk

# Install specific components
choco install android-sdk-platform-tools
choco install android-sdk-build-tools
```

---

## What You'll Have After Installation:
- ✅ Android SDK (minimal)
- ✅ Platform-tools (adb, fastboot)
- ✅ Build-tools (aapt, zipalign, etc.)
- ✅ SDK Platform (Android API 33 or 34)
- ❌ Android Studio IDE (not needed for building)
- ❌ Emulator (not needed if using real device)

## File Sizes:
- Command-line tools: ~150 MB
- After installing components: ~1-2 GB total
- (vs Android Studio full install: ~3-5 GB)

---

## Quick Reference Commands:
```powershell
# Check what's installed
sdkmanager --list

# Update all components
sdkmanager --update

# Install a specific package
sdkmanager "platforms;android-34"
```
