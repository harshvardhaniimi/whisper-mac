#!/bin/bash

set -e

echo "🎤 Setting up Whisper Mac..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only."
    exit 1
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p Sources/WhisperCpp/include
mkdir -p Sources/WhisperCpp/src

# Clone whisper.cpp if it doesn't exist
if [ ! -d "whisper.cpp" ]; then
    echo "📥 Cloning whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git
else
    echo "✅ whisper.cpp already exists"
fi

# Copy necessary files from whisper.cpp to our project
echo "📋 Copying whisper.cpp files..."
cp whisper.cpp/whisper.h Sources/WhisperCpp/include/
cp whisper.cpp/whisper.cpp Sources/WhisperCpp/src/
cp whisper.cpp/ggml.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml.c Sources/WhisperCpp/src/
cp whisper.cpp/ggml-alloc.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml-alloc.c Sources/WhisperCpp/src/
cp whisper.cpp/ggml-backend.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml-backend.c Sources/WhisperCpp/src/

# Rename .c files to .cpp for Swift Package Manager
echo "🔧 Preparing source files..."
for file in Sources/WhisperCpp/src/*.c; do
    if [ -f "$file" ]; then
        mv "$file" "${file%.c}.cpp"
    fi
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode:"
echo "   open Package.swift"
echo ""
echo "2. Build the project (⌘+B)"
echo ""
echo "3. Run the app (⌘+R)"
echo ""
echo "Note: The app will need to download Whisper models on first use."
echo "      Models are stored in ~/Library/Application Support/WhisperMac/models/"
echo ""
