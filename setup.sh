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
mkdir -p Sources/WhisperCpp/metal

# Clone whisper.cpp if it doesn't exist
if [ ! -d "whisper.cpp" ]; then
    echo "📥 Cloning whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git
else
    echo "✅ whisper.cpp already exists"
fi

# Copy necessary files from whisper.cpp to our project
echo "📋 Copying whisper.cpp files..."

# Copy whisper files
cp whisper.cpp/include/whisper.h Sources/WhisperCpp/include/
cp whisper.cpp/src/whisper.cpp Sources/WhisperCpp/src/
cp whisper.cpp/src/whisper-arch.h Sources/WhisperCpp/include/

# Copy ggml headers
cp whisper.cpp/ggml/include/ggml.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml/include/ggml-alloc.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml/include/ggml-backend.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml/include/ggml-cpu.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml/include/ggml-metal.h Sources/WhisperCpp/include/

# Copy ggml source files
cp whisper.cpp/ggml/src/ggml.c Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-alloc.c Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-backend.cpp Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-backend-impl.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml/src/ggml-backend-reg.cpp Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-common.h Sources/WhisperCpp/include/
cp whisper.cpp/ggml/src/ggml-impl.h Sources/WhisperCpp/include/

# Copy CPU implementation
if [ -d "whisper.cpp/ggml/src/ggml-cpu" ]; then
    echo "📋 Copying CPU implementation..."
    cp whisper.cpp/ggml/src/ggml-cpu/*.cpp Sources/WhisperCpp/src/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-cpu/*.h Sources/WhisperCpp/include/ 2>/dev/null || true
fi

# Copy Metal implementation if it exists
if [ -d "whisper.cpp/ggml/src/ggml-metal" ]; then
    echo "📋 Copying Metal implementation..."
    cp whisper.cpp/ggml/src/ggml-metal/*.h Sources/WhisperCpp/include/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-metal/*.m Sources/WhisperCpp/src/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-metal/*.metal Sources/WhisperCpp/metal/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-metal/*.cpp Sources/WhisperCpp/src/ 2>/dev/null || true
fi

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
