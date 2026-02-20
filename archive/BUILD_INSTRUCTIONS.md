# Build Instructions

This guide will help you build and run the Kalam app from source.

## Prerequisites

- **macOS 13.0 (Ventura) or later**
- **Xcode 15.0 or later** with Swift 5.9+
- **Command Line Tools** for Xcode
- **Git**

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd whisper-mac
```

### 2. Run Setup Script

The setup script will download whisper.cpp and prepare the project:

```bash
chmod +x setup.sh
./setup.sh
```

This script will:
- Clone the whisper.cpp repository
- Copy necessary source files to the project
- Prepare the project structure

### 3. Open in Xcode

```bash
open Package.swift
```

Alternatively, you can open it from Xcode:
- Launch Xcode
- File → Open → Select `Package.swift`

### 4. Build the Project

In Xcode:
- Select the `Kalam` scheme
- Press ⌘+B to build
- Or Product → Build

### 5. Run the App

- Press ⌘+R to run
- Or Product → Run

The app will appear in your menu bar with a waveform icon.

## First Launch

On first launch, you'll need to download at least one Whisper model:

1. Click the menu bar icon
2. Click the settings gear icon
3. In the Models section, click "Download" for a model
   - **Base** (142 MB) - Recommended for most users
   - **Small** (466 MB) - Better accuracy
   - **Medium** (1.5 GB) - High accuracy (requires good hardware)

Models are downloaded from Hugging Face and stored in:
```
~/Library/Application Support/Kalam/models/
```

## Building from Command Line

If you prefer to build from the command line:

```bash
# Build
swift build -c release

# Run
swift run
```

## Troubleshooting

### Build Errors (Invalid Exclude, C++ Compilation Errors)

If you encounter any build errors, run the fix script:
```bash
./fix-build.sh
```

This will automatically fix:
- Invalid Exclude path errors
- C++ compilation errors in ggml-alloc
- Xcode derived data issues

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### "Command Line Tools not found"

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### Build errors related to whisper.cpp

Make sure you've run the setup script:
```bash
./setup.sh
```

If issues persist after setup:
```bash
./fix-build.sh
```

### Microphone permission denied

Go to:
- System Settings → Privacy & Security → Microphone
- Enable permission for "Kalam"

### App doesn't appear in menu bar

Make sure `LSUIElement` is set to `true` in `Info.plist`. This makes the app a menu bar app without a Dock icon.

### Model download fails

Check your internet connection and try again. Models are large files (75 MB - 2.9 GB) and may take time to download.

### Performance issues

- Make sure you're using an appropriate model size for your hardware
- Apple Silicon Macs (M1/M2/M3) will have much better performance
- Close other resource-intensive applications
- Try using a smaller model (tiny or base)

## Project Structure

```
whisper-mac/
├── Package.swift              # Swift Package Manager configuration
├── Info.plist                 # App configuration
├── setup.sh                   # Setup script
├── Sources/
│   ├── Kalam/               # Main app code
│   │   ├── KalamApp.swift           # App entry point
│   │   ├── Models/                   # Data models
│   │   ├── Services/                 # Core services
│   │   └── Views/                    # UI components
│   └── WhisperCpp/           # whisper.cpp integration
│       ├── include/          # Headers
│       └── src/              # Source files
└── whisper.cpp/              # Git clone (not committed)
```

## Development

### Code Style

- Use Swift 5.9+ features
- Follow Apple's Swift API Design Guidelines
- Use SwiftUI for all UI components
- Keep views small and focused
- Use async/await for asynchronous operations

### Testing

To test audio recording:
1. Run the app
2. Click "Record"
3. Speak into your microphone
4. Click "Stop Recording"
5. Wait for transcription to complete

To test file transcription:
1. Open the main window (click Kalam in menu bar, then expand)
2. Drag and drop an audio file (MP3, WAV, M4A, etc.)
3. Wait for transcription

### Debugging

Enable debug logging:
```swift
// In WhisperService.swift
let params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
params.print_progress = true  // Enable progress logging
```

## Apple Silicon Optimization

The app is optimized for Apple Silicon using:
- **Accelerate Framework** for fast math operations
- **Metal** for GPU acceleration
- **Core Audio** for efficient audio processing

Performance comparison:
- **M1/M2/M3**: ~10x faster than Intel Macs
- **Base model**: Real-time transcription (1min audio = ~6s processing)
- **Large model**: ~30-60s for 1min audio

## Distribution

To create a distributable app:

1. Archive the app in Xcode:
   - Product → Archive
   - Wait for archiving to complete

2. Distribute:
   - Window → Organizer
   - Select your archive
   - Click "Distribute App"
   - Choose distribution method (Developer ID for distribution outside App Store)

3. Code sign:
   - You'll need a Developer ID certificate
   - Enable Hardened Runtime
   - Enable App Sandbox (with appropriate entitlements)

4. Notarize:
   - Required for distribution on macOS 10.15+
   - Automated through Xcode
   - See Apple's notarization documentation

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project uses OpenAI's Whisper model, which is licensed under the MIT License.

## Support

For issues and questions:
- Check the troubleshooting section above
- Review the README.md
- Open an issue on GitHub

## Credits

- **OpenAI Whisper**: https://github.com/openai/whisper
- **whisper.cpp**: https://github.com/ggerganov/whisper.cpp
- **Design inspiration**: Apple HIG, Claude.ai

---

Happy transcribing! 🎤✨
