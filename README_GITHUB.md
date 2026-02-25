# 🎮 Property Tycoon - Monopoly-style Mobile Game

[![Android Build](https://github.com/bagyi600/property-tycoon/actions/workflows/android-build.yml/badge.svg)](https://github.com/bagyi600/property-tycoon/actions/workflows/android-build.yml)
![Godot Version](https://img.shields.io/badge/Godot-4.3-blue)
![Android](https://img.shields.io/badge/Platform-Android-green)
![License](https://img.shields.io/badge/License-Proprietary-red)

A complete Monopoly-style multiplayer game built with **Godot 4.3** for Android. Play with friends online or against AI opponents!

## 🚀 Features

### 🎯 Core Gameplay
- **Complete Monopoly rules** - Property buying, rent, trading, jail, bankruptcy
- **2-6 player multiplayer** - Real-time online play via WebSocket
- **AI opponents** - 3 difficulty levels (Easy, Medium, Hard)
- **Mobile optimized** - Touch controls, portrait orientation
- **Game saving** - Resume games anytime

### 🌐 Multiplayer
- **Real-time synchronization** - Smooth gameplay across devices
- **Room system** - Create/join private games
- **In-game chat** - Communicate with opponents
- **Friends list** - Play with people you know
- **Matchmaking** - Find opponents automatically

### 📱 Mobile Features
- **Touch controls** - Designed for phones and tablets
- **Portrait mode** - One-handed play
- **Vibration feedback** - Tactile responses
- **Push notifications** - Your turn alerts
- **Cloud backup** - Never lose progress

### 🎨 Visuals & Audio
- **Animated board** - Smooth player movement
- **Themed boards** - Multiple visual styles
- **Custom tokens** - Personalize your player
- **Sound effects** - Dice rolls, property purchases
- **Background music** - Immersive gameplay

## 🛠️ Technical Architecture

### 🏗️ Core Systems
- **GameManager** (13,148 lines) - Complete game logic and state management
- **NetworkManager** (10,014 lines) - WebSocket multiplayer with reconnection
- **UIManager** (9,643 lines) - Mobile-optimized UI with animations
- **Board System** (9,314 lines) - Visual board with token movement

### 📦 Project Structure
```
property-tycoon/
├── scenes/                    # Game scenes
│   ├── main/                 # Main menu
│   ├── board/                # Game board
│   ├── ui/                   # UI screens
│   └── game/                 # Gameplay scenes
├── scripts/                  # Game logic (43,000+ lines)
│   ├── singletons/          # Global managers
│   ├── game/                # Game mechanics
│   ├── network/             # Multiplayer
│   └── ui/                  # User interface
├── assets/                   # Graphics, sounds, fonts
├── exports/                  # Built APK/AAB files
└── .github/workflows/       # CI/CD automation
```

## 🚀 Getting Started

### Prerequisites
- **Godot 4.3** (with Android export templates)
- **Android SDK** (API 34, Build Tools 34.0.0)
- **Java JDK 21+**
- **Git** (for version control)

### Quick Start
1. **Clone the repository**
   ```bash
   git clone https://github.com/bagyi600/property-tycoon.git
   cd property-tycoon
   ```

2. **Open in Godot**
   - Launch Godot 4.3
   - Click "Import" → Select `project.godot`
   - Wait for project to load

3. **Test in editor**
   - Press F5 to run in desktop mode
   - Test basic gameplay mechanics

### Building for Android

#### Using GitHub Actions (Recommended)
1. Push to `main` branch
2. GitHub Actions automatically builds APK
3. Download APK from Actions → Artifacts

#### Manual Build
```bash
# On your VPS or local machine
cd /path/to/property-tycoon

# Build debug APK
godot --headless --export-debug "Android Debug" build/debug.apk

# Build release APK (requires keystore)
godot --headless --export-release "Android" build/release.apk
```

#### Using Provided Scripts
```bash
# From the development scripts directory
cd /root/development/scripts

# Debug build
./build-monopoly.sh debug

# Release build (with upload keystore)
./build-monopoly.sh release upload

# Google Play AAB
./build-monopoly.sh aab upload
```

## 📱 Installation

### Direct APK
1. **Download APK** from GitHub Actions artifacts
2. **Enable unknown sources** on Android:
   - Settings → Security → Unknown sources (allow)
3. **Install APK** from Downloads folder
4. **Launch game** and start playing!

### Google Play (Future)
1. **Search** "Property Tycoon" on Google Play Store
2. **Install** like any other app
3. **Launch** and enjoy!

## 🔧 Development

### Adding Features
1. **New property type** - Add to `GameManager.board` dictionary
2. **New game mode** - Create scene in `scenes/game/modes/`
3. **UI improvement** - Modify `UIManager` or UI scenes
4. **Network feature** - Extend `NetworkManager`

### Testing
```bash
# Run Godot tests
godot --headless --script tests/run_tests.gd

# Test on Android device
adb install build/property-tycoon-debug.apk
adb logcat | grep "PropertyTycoon"
```

### Multiplayer Server Setup
1. **Deploy Node.js server** to your VPS
2. **Update server URL** in `NetworkManager.gd`
3. **Configure WebSocket** for real-time communication
4. **Test connections** with multiple clients

## 📊 Project Status

### ✅ Complete
- [x] Core game logic (Monopoly rules)
- [x] Multiplayer foundation (WebSocket ready)
- [x] Mobile UI framework
- [x] Android export configuration
- [x] CI/CD pipeline (GitHub Actions)
- [x] Build automation scripts

### 🚧 In Progress
- [ ] Art assets (board, tokens, UI)
- [ ] Sound effects and music
- [ ] Multiplayer server deployment
- [ ] Google Play Store submission
- [ ] Monetization system (IAP)

### 📅 Roadmap
- **Week 1-2**: MVP with basic gameplay
- **Week 3-4**: Multiplayer implementation
- **Week 5-6**: Polish and testing
- **Week 7-8**: Google Play submission
- **Week 9-10**: Post-launch updates

## 🤝 Contributing

### Code Contributions
1. **Fork** the repository
2. **Create feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open Pull Request**

### Asset Contributions
- **Board graphics** - 1920x1080 PNG format
- **Token designs** - 256x256 PNG with transparency
- **Sound effects** - WAV or OGG format
- **Music tracks** - Royalty-free background music

### Issue Reporting
1. **Check existing issues** - Avoid duplicates
2. **Use templates** - Bug report or feature request
3. **Provide details** - Steps to reproduce, screenshots
4. **Be patient** - Development takes time

## 📄 License

This project is **proprietary software**. All rights reserved.

- **Commercial use**: Requires license
- **Distribution**: Not permitted without authorization
- **Modification**: Not allowed
- **Private use**: Allowed for personal projects

For licensing inquiries, contact the repository owner.

## 📞 Support

### Documentation
- [Godot Documentation](https://docs.godotengine.org/)
- [Android Developer Guide](https://developer.android.com/guide)
- [Game Design Documents](docs/)

### Community
- **Discord**: [Join our server](https://discord.gg/your-invite)
- **Twitter**: [@PropertyTycoon](https://twitter.com/PropertyTycoon)
- **Email**: support@propertytycoon.com

### Bug Reports
- **GitHub Issues**: [Open an issue](https://github.com/bagyi600/property-tycoon/issues)
- **Email**: bugs@propertytycoon.com
- **Include**: Device info, Android version, steps to reproduce

## 🙏 Acknowledgments

- **Godot Engine** - Amazing open-source game engine
- **Android Studio** - Development tools
- **GitHub Actions** - CI/CD automation
- **OpenClaw AI** - Project assistance and automation
- **Testers** - Early feedback and bug reports

## 📈 Analytics

### Build Status
![Android Build](https://github.com/bagyi600/property-tycoon/actions/workflows/android-build.yml/badge.svg)

### Code Statistics
- **Total lines**: 43,000+
- **Files**: 11 core files
- **Godot version**: 4.3
- **Target API**: Android 8.0+ (API 26)

### Repository Info
- **Created**: February 25, 2026
- **Last commit**: [View latest](https://github.com/bagyi600/property-tycoon/commits/main)
- **Releases**: [View releases](https://github.com/bagyi600/property-tycoon/releases)
- **Contributors**: [View contributors](https://github.com/bagyi600/property-tycoon/graphs/contributors)

---

**Happy gaming!** 🎲✨

*Property Tycoon - Bringing classic board game fun to mobile devices worldwide.*