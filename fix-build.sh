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

# Function to apply C++ fixes to all ggml files
fix_ggml_files() {
    echo "🔨 Applying C++ compatibility fixes..."

    local fixed_count=0

    # Fix ggml-alloc.cpp
    if [ -f "Sources/WhisperCpp/src/ggml-alloc.cpp" ]; then
        echo "  → Fixing ggml-alloc.cpp..."
        TMP_FILE=$(mktemp)
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
        if ! diff -q Sources/WhisperCpp/src/ggml-alloc.cpp "$TMP_FILE" > /dev/null 2>&1; then
            mv "$TMP_FILE" Sources/WhisperCpp/src/ggml-alloc.cpp
            echo "    ✓ Fixed ggml-alloc.cpp (8 casts)"
            ((fixed_count++))
        else
            rm -f "$TMP_FILE"
            echo "    ℹ️  ggml-alloc.cpp already fixed"
        fi
    fi

    # Fix ggml-quants.cpp
    if [ -f "Sources/WhisperCpp/src/ggml-quants.cpp" ]; then
        echo "  → Fixing ggml-quants.cpp..."
        TMP_FILE=$(mktemp)
        sed -E \
            -e 's/block_iq2_xxs \* y = vy;/block_iq2_xxs * y = (block_iq2_xxs *)vy;/g' \
            -e 's/block_iq2_xs \* y = vy;/block_iq2_xs * y = (block_iq2_xs *)vy;/g' \
            -e 's/block_iq3_xxs \* y = vy;/block_iq3_xxs * y = (block_iq3_xxs *)vy;/g' \
            -e 's/block_iq3_s \* y = vy;/block_iq3_s * y = (block_iq3_s *)vy;/g' \
            -e 's/block_iq1_s \* y = vy;/block_iq1_s * y = (block_iq1_s *)vy;/g' \
            -e 's/block_iq1_m \* y = vy;/block_iq1_m * y = (block_iq1_m *)vy;/g' \
            -e 's/block_iq2_s \* y = vy;/block_iq2_s * y = (block_iq2_s *)vy;/g' \
            Sources/WhisperCpp/src/ggml-quants.cpp > "$TMP_FILE"
        if ! diff -q Sources/WhisperCpp/src/ggml-quants.cpp "$TMP_FILE" > /dev/null 2>&1; then
            mv "$TMP_FILE" Sources/WhisperCpp/src/ggml-quants.cpp
            echo "    ✓ Fixed ggml-quants.cpp (8 casts)"
            ((fixed_count++))
        else
            rm -f "$TMP_FILE"
            echo "    ℹ️  ggml-quants.cpp already fixed"
        fi
    fi

    # Fix quants.cpp (from ggml-cpu)
    if [ -f "Sources/WhisperCpp/src/quants.cpp" ]; then
        echo "  → Fixing quants.cpp (CPU implementation)..."
        TMP_FILE=$(mktemp)
        sed -E \
            -e 's/const block_q([0-9_K]+) \* GGML_RESTRICT x = vx;/const block_q\1 * GGML_RESTRICT x = (const block_q\1 *)vx;/g' \
            -e 's/const block_q([0-9_K]+) \* GGML_RESTRICT y = vy;/const block_q\1 * GGML_RESTRICT y = (const block_q\1 *)vy;/g' \
            -e 's/block_q([0-9_K]+) \* GGML_RESTRICT x = vx;/block_q\1 * GGML_RESTRICT x = (block_q\1 *)vx;/g' \
            -e 's/block_q([0-9_K]+) \* GGML_RESTRICT y = vy;/block_q\1 * GGML_RESTRICT y = (block_q\1 *)vy;/g' \
            -e 's/const block_iq([0-9_a-z]+) \* GGML_RESTRICT x = vx;/const block_iq\1 * GGML_RESTRICT x = (const block_iq\1 *)vx;/g' \
            -e 's/const block_iq([0-9_a-z]+) \* GGML_RESTRICT y = vy;/const block_iq\1 * GGML_RESTRICT y = (const block_iq\1 *)vy;/g' \
            -e 's/block_iq([0-9_a-z]+) \* GGML_RESTRICT x = vx;/block_iq\1 * GGML_RESTRICT x = (block_iq\1 *)vx;/g' \
            -e 's/block_iq([0-9_a-z]+) \* GGML_RESTRICT y = vy;/block_iq\1 * GGML_RESTRICT y = (block_iq\1 *)vy;/g' \
            Sources/WhisperCpp/src/quants.cpp > "$TMP_FILE"
        if ! diff -q Sources/WhisperCpp/src/quants.cpp "$TMP_FILE" > /dev/null 2>&1; then
            mv "$TMP_FILE" Sources/WhisperCpp/src/quants.cpp
            echo "    ✓ Fixed quants.cpp (49 casts)"
            ((fixed_count++))
        else
            rm -f "$TMP_FILE"
            echo "    ℹ️  quants.cpp already fixed"
        fi
    fi

    if [ $fixed_count -eq 0 ]; then
        echo "  ℹ️  All files already fixed or not found. Run ./setup.sh if you need to set up the project."
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
fix_ggml_files

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
