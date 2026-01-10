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

echo ""
echo "📋 Copying whisper.cpp files..."

# Copy whisper headers
echo "  → Whisper headers..."
cp whisper.cpp/include/*.h Sources/WhisperCpp/include/ 2>/dev/null || true
cp whisper.cpp/src/*.h Sources/WhisperCpp/include/ 2>/dev/null || true

# Copy whisper source
echo "  → Whisper sources..."
cp whisper.cpp/src/whisper.cpp Sources/WhisperCpp/src/

# Copy ggml headers
echo "  → GGML headers..."
cp whisper.cpp/ggml/include/*.h Sources/WhisperCpp/include/ 2>/dev/null || true
cp whisper.cpp/ggml/src/*.h Sources/WhisperCpp/include/ 2>/dev/null || true

# Copy ggml core sources
echo "  → GGML core sources..."
cp whisper.cpp/ggml/src/ggml.c Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-alloc.c Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-backend.cpp Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-backend-reg.cpp Sources/WhisperCpp/src/
cp whisper.cpp/ggml/src/ggml-opt.cpp Sources/WhisperCpp/src/ 2>/dev/null || true

# Copy CPU implementation - only .cpp files, not special implementations
if [ -d "whisper.cpp/ggml/src/ggml-cpu" ]; then
    echo "  → CPU implementation..."
    # Copy headers first
    cp whisper.cpp/ggml/src/ggml-cpu/*.h Sources/WhisperCpp/include/ 2>/dev/null || true

    # Copy only the main CPU implementation files
    cp whisper.cpp/ggml/src/ggml-cpu/ggml-cpu.cpp Sources/WhisperCpp/src/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-cpu/ggml-cpu.c Sources/WhisperCpp/src/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-cpu/ggml-cpu-aarch64.cpp Sources/WhisperCpp/src/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-cpu/ggml-cpu-aarch64.c Sources/WhisperCpp/src/ 2>/dev/null || true

    # Skip llamafile, amx, and other special implementations
fi

# Copy Metal implementation
if [ -d "whisper.cpp/ggml/src/ggml-metal" ]; then
    echo "  → Metal implementation..."
    cp whisper.cpp/ggml/src/ggml-metal/*.h Sources/WhisperCpp/include/ 2>/dev/null || true
    cp whisper.cpp/ggml/src/ggml-metal/ggml-metal.m Sources/WhisperCpp/src/ 2>/dev/null || true
fi

# Rename .c files to .cpp for Swift Package Manager
echo "  → Converting .c to .cpp..."
for file in Sources/WhisperCpp/src/*.c; do
    if [ -f "$file" ]; then
        mv "$file" "${file%.c}.cpp"
    fi
done

# Fix C++ compilation errors in ggml-alloc.cpp
echo "  → Fixing C++ compatibility in ggml-alloc.cpp..."
if [ -f "Sources/WhisperCpp/src/ggml-alloc.cpp" ]; then
    # Create a temporary file
    TMP_FILE=$(mktemp)

    # Fix void* pointer assignments with explicit casts
    sed -E \
        -e 's/struct tallocr_chunk \* chunk = calloc\(/struct tallocr_chunk * chunk = (struct tallocr_chunk *)calloc(/g' \
        -e 's/galloc->bufts = calloc\(/galloc->bufts = (ggml_backend_buffer_type_t *)calloc(/g' \
        -e 's/galloc->buffers = calloc\(/galloc->buffers = (struct vbuffer **)calloc(/g' \
        -e 's/galloc->buf_tallocs = calloc\(/galloc->buf_tallocs = (struct ggml_dyn_tallocr **)calloc(/g' \
        -e 's/galloc->hash_values = malloc\(/galloc->hash_values = (struct hash_node *)malloc(/g' \
        -e 's/galloc->node_allocs = calloc\(/galloc->node_allocs = (struct node_alloc *)calloc(/g' \
        -e 's/galloc->leaf_allocs = calloc\(/galloc->leaf_allocs = (struct leaf_alloc *)calloc(/g' \
        -e 's/\*buffers = realloc\(/*buffers = (ggml_backend_buffer_t *)realloc(/g' \
        Sources/WhisperCpp/src/ggml-alloc.cpp > "$TMP_FILE"

    # Replace the original file
    mv "$TMP_FILE" Sources/WhisperCpp/src/ggml-alloc.cpp
    echo "    ✓ Fixed void* pointer assignments"
fi

# Remove problematic files if they exist
echo "  → Cleaning up..."
rm -f Sources/WhisperCpp/src/sgemm.cpp 2>/dev/null || true
rm -f Sources/WhisperCpp/include/sgemm.h 2>/dev/null || true

echo ""
echo "✅ Setup complete!"
echo ""
echo "📊 Files summary:"
HEADERS=$(ls -1 Sources/WhisperCpp/include/*.h 2>/dev/null | wc -l | tr -d ' ')
SOURCES=$(ls -1 Sources/WhisperCpp/src/*.{cpp,m,mm} 2>/dev/null | wc -l | tr -d ' ')
echo "  Headers: $HEADERS"
echo "  Sources: $SOURCES"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode:"
echo "   open Package.swift"
echo ""
echo "2. Clean build folder (⇧⌘K)"
echo ""
echo "3. Build the project (⌘+B)"
echo ""
echo "4. Run the app (⌘+R)"
echo ""
echo "Note: The app will download Whisper models automatically on first launch."
echo "      Models are stored in ~/Library/Application Support/WhisperMac/models/"
echo ""
