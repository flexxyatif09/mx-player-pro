# MX Player Pro Clone 🎬

A professional Flutter video player app inspired by MX Player, with full offline support and beautiful dark UI.

## ✨ Features

| Feature | Status |
|---------|--------|
| 🎬 Video Playback (MP4, MKV, AVI, etc.) | ✅ |
| 🎵 Audio Player | ✅ |
| 📁 File Browser | ✅ |
| 🌐 Network Stream (HTTP, RTMP, M3U8) | ✅ |
| 🌙 Dark/Light Theme | ✅ |
| 🔍 Search Videos | ✅ |
| 📊 Sort by Name/Date/Size/Duration | ✅ |
| 🔒 Screen Lock | ✅ |
| ⏩ Swipe to Seek | ✅ |
| 🔆 Swipe for Brightness (Left side) | ✅ |
| 🔊 Swipe for Volume (Right side) | ✅ |
| 👆 Double-tap to seek ±10s | ✅ |
| ▶️ Playback Speed Control | ✅ |
| 📱 Grid & List View | ✅ |
| 🔄 Auto-play Next | ✅ |
| 📌 Recent History | ✅ |

## 📲 Download APK (No PC needed!)

### Method 1: GitHub Actions (Automatic)
1. Fork this repo on GitHub
2. Go to **Actions** tab
3. Click **Build & Sign MX Player APK**
4. Click **Run workflow** → **Run workflow**
5. Wait ~5 minutes
6. Download APK from **Artifacts** section

### Method 2: Every Push Auto-Builds
- Every time you push code, APK builds automatically
- Download from GitHub Actions → Your latest run → Artifacts

## 🔑 Optional: Sign Your APK

For a properly signed APK (needed for Play Store), add these GitHub Secrets:

### Create Keystore (Run on PC or Termux):
```bash
keytool -genkey -v -keystore my-key.jks \
  -alias mxplayer -keyalg RSA -keysize 2048 \
  -validity 10000
  
# Convert to base64:
base64 my-key.jks > keystore-base64.txt
```

### Add GitHub Secrets:
Go to: **Repo Settings** → **Secrets** → **Actions** → **New secret**

| Secret Name | Value |
|-------------|-------|
| `KEYSTORE_BASE64` | Content of keystore-base64.txt |
| `KEY_STORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | mxplayer |
| `KEY_PASSWORD` | Your key password |

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry
├── models/
│   └── video_model.dart      # Video data model
├── providers/
│   ├── media_provider.dart   # Scan & manage media
│   ├── player_provider.dart  # Player settings
│   └── theme_provider.dart   # Theme switching
├── screens/
│   ├── splash_screen.dart    # Animated splash
│   ├── home_screen.dart      # Main navigation
│   ├── videos_screen.dart    # Video browser
│   ├── audio_screen.dart     # Audio player
│   ├── files_screen.dart     # File browser
│   ├── stream_screen.dart    # Network streams
│   ├── more_screen.dart      # Settings & more
│   └── player_screen.dart    # Video player
├── widgets/
│   ├── bottom_nav_bar.dart   # Custom nav bar
│   ├── player_controls.dart  # Player UI overlay
│   ├── player_gestures.dart  # Touch gestures
│   └── video_card.dart       # Video thumbnails
└── utils/
    └── app_theme.dart        # Colors & themes
```

## 📦 Dependencies

- `video_player` - Core video playback
- `chewie` - Enhanced player controls
- `better_player` - Advanced features (subtitles, HLS)
- `permission_handler` - Storage permissions
- `hive` - Local database
- `provider` + `get` - State management
- `google_fonts` - Typography

## 🚀 Build Locally (if you have Flutter)

```bash
git clone https://github.com/YOUR_USERNAME/mx-player-clone
cd mx-player-clone
flutter pub get
flutter run
# or
flutter build apk --release
```

## 📱 Install on Phone

1. Download APK from GitHub Actions
2. Open APK file on phone
3. Allow "Install from unknown sources"
4. Enjoy!

---
Made with ❤️ Flutter

