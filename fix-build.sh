#!/bin/bash

# fix-build.sh - Fix common build issues for Whisper Mac project

set -e

echo "🔧 Fixing Whisper Mac build issues..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only."
    exit 1
fi

# Function to clean Xcode derived data
clean_xcode_data() {
    echo "🧹 Cleaning Xcode derived data..."

    # Clean derived data for this project
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        echo "  → Removing Xcode DerivedData..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/WhisperMac-* 2>/dev/null || true
        echo "    ✓ Cleared Xcode DerivedData"
    fi

    # Clean Xcode workspace data
    if [ -f .swiftpm/xcode/package.xcworkspace/xcuserdata ]; then
        echo "  → Removing workspace user data..."
        rm -rf .swiftpm/xcode/package.xcworkspace/xcuserdata 2>/dev/null || true
        echo "    ✓ Cleared workspace data"
    fi

    # Clean Swift Package Manager build folder
    if [ -d .build ]; then
        echo "  → Removing .build folder..."
        rm -rf .build
        echo "    ✓ Cleared .build folder"
    fi

    echo ""
}

# Function to re-run setup
rerun_setup() {
    echo "🔄 Re-running setup to fix C++ compatibility issues..."

    if [ -f setup.sh ]; then
        ./setup.sh
    else
        echo "  ⚠️  setup.sh not found. Skipping..."
    fi

    echo ""
}

# Function to apply C++ fixes to ggml-alloc.cpp if it already exists
fix_ggml_alloc() {
    echo "🔨 Applying C++ compatibility fixes..."

    if [ -f "Sources/WhisperCpp/src/ggml-alloc.cpp" ]; then
        echo "  → Fixing ggml-alloc.cpp..."

        # Create a backup
        cp Sources/WhisperCpp/src/ggml-alloc.cpp Sources/WhisperCpp/src/ggml-alloc.cpp.bak

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

        # Check if changes were made
        if ! diff -q Sources/WhisperCpp/src/ggml-alloc.cpp "$TMP_FILE" > /dev/null 2>&1; then
            mv "$TMP_FILE" Sources/WhisperCpp/src/ggml-alloc.cpp
            echo "    ✓ Applied fixes to ggml-alloc.cpp"
            rm -f Sources/WhisperCpp/src/ggml-alloc.cpp.bak
        else
            echo "    ℹ️  ggml-alloc.cpp already fixed"
            rm -f "$TMP_FILE"
            rm -f Sources/WhisperCpp/src/ggml-alloc.cpp.bak
        fi
    else
        echo "  ⚠️  ggml-alloc.cpp not found. Run ./setup.sh first."
    fi

    echo ""
}

# Main execution
echo "This script will:"
echo "  1. Clean Xcode derived data and build folders"
echo "  2. Fix C++ compilation errors in ggml-alloc.cpp"
echo "  3. Prepare project for clean build"
echo ""

# Prompt for confirmation
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Execute fixes
clean_xcode_data
fix_ggml_alloc

echo "✅ All fixes applied!"
echo ""
echo "📋 Next steps:"
echo "1. Open the project in Xcode:"
echo "   open Package.swift"
echo ""
echo "2. Clean build folder in Xcode:"
echo "   Press ⇧⌘K (Shift+Command+K)"
echo ""
echo "3. Build the project:"
echo "   Press ⌘B (Command+B)"
echo ""
echo "4. If you still see 'Invalid Exclude' errors:"
echo "   - Close Xcode completely"
echo "   - Run this script again"
echo "   - Reopen the project"
echo ""
