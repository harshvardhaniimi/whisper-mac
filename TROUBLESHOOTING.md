# Troubleshooting Guide

This guide helps resolve common build issues with the Whisper Mac project.

## Quick Fix

If you're experiencing build errors, run the fix script:

```bash
./fix-build.sh
```

This will automatically:
- Clean Xcode derived data
- Fix C++ compilation errors
- Prepare the project for a clean build

## Common Issues

### 1. Invalid Exclude Path Errors

**Symptoms:**
```
Invalid Exclude /Users/username/...
```

**Cause:** Xcode's derived data contains absolute paths from a previous build or different machine.

**Solution:**

```bash
# Option 1: Use the fix script
./fix-build.sh

# Option 2: Manual cleanup
rm -rf ~/Library/Developer/Xcode/DerivedData/WhisperMac-*
rm -rf .build
rm -rf .swiftpm
```

Then in Xcode:
1. Close Xcode completely
2. Reopen the project: `open Package.swift`
3. Clean build folder: Press ⇧⌘K (Shift+Command+K)
4. Build: Press ⌘B (Command+B)

### 2. C++ Compilation Errors in ggml Files

**Symptoms:**
```
Cannot initialize a variable of type 'struct tallocr_chunk *' with an rvalue of type 'void *'
Assigning to 'ggml_backend_buffer_type_t *' from incompatible type 'void *'
Cannot initialize a variable of type 'const block_q4_0 *' with an rvalue of type 'void *'
Assigning to 'block_iq2_xxs *' from incompatible type 'void *'
```

**Cause:** Multiple `.c` files are renamed to `.cpp` for Swift Package Manager, but C++ requires explicit casts from `void*`. This affects 3 files with 65 total issues:
- `ggml-alloc.cpp` (8 issues) - malloc/calloc/realloc casts
- `ggml-quants.cpp` (8 issues) - block_iq* pointer assignments
- `quants.cpp` (49 issues) - block_q* pointer assignments in CPU implementation

**Solution:**

The updated `setup.sh` automatically fixes ALL these issues. If you already ran setup before this fix:

```bash
# Option 1: Use the fix script (recommended)
./fix-build.sh

# Option 2: Re-run setup
./setup.sh
```

The fixes add explicit type casts to:
- All `malloc`, `calloc`, and `realloc` calls
- All void* to typed pointer assignments (block_q*, block_iq* structs)

### 3. Missing Source Files

**Symptoms:**
```
No such file or directory: 'Sources/WhisperCpp/src/ggml.cpp'
```

**Cause:** The setup script hasn't been run yet, or the whisper.cpp repository wasn't cloned properly.

**Solution:**

```bash
# Run the setup script
./setup.sh

# If that fails, try a clean setup
rm -rf whisper.cpp
rm -rf Sources/WhisperCpp/src
rm -rf Sources/WhisperCpp/include
./setup.sh
```

### 4. Metal Compilation Errors

**Symptoms:**
```
Use of undeclared identifier in Metal code
```

**Cause:** Metal headers or sources are missing or corrupted.

**Solution:**

```bash
# Clean and re-run setup
rm -rf Sources/WhisperCpp/src
rm -rf Sources/WhisperCpp/include
./setup.sh
```

### 5. Linker Errors

**Symptoms:**
```
Undefined symbols for architecture arm64
```

**Cause:** Missing framework links or incomplete source files.

**Solution:**

1. Verify all frameworks are linked in Package.swift:
   - Accelerate
   - Metal
   - MetalKit
   - Foundation

2. Clean and rebuild:
   ```bash
   ./fix-build.sh
   ```

### 6. Swift Package Manager Cache Issues

**Symptoms:**
- Build succeeds in Xcode but fails from command line
- Inconsistent build behavior

**Solution:**

```bash
# Reset Swift Package Manager
swift package reset
swift package clean

# Or use the fix script
./fix-build.sh
```

## Build from Scratch

If you want to start completely fresh:

```bash
# 1. Remove all generated files
rm -rf whisper.cpp
rm -rf Sources/WhisperCpp/src
rm -rf Sources/WhisperCpp/include
rm -rf .build
rm -rf .swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/WhisperMac-*

# 2. Run setup
./setup.sh

# 3. Open in Xcode
open Package.swift

# 4. Clean and build
# In Xcode: ⇧⌘K then ⌘B
```

## Verification Steps

After applying fixes, verify the build:

```bash
# 1. Check that source files exist
ls -la Sources/WhisperCpp/src/
ls -la Sources/WhisperCpp/include/

# 2. Check for C++ compatibility fixes
grep -n "struct tallocr_chunk \*)" Sources/WhisperCpp/src/ggml-alloc.cpp

# 3. Try command-line build
swift build

# 4. Try Xcode build
open Package.swift
# Then: ⌘B in Xcode
```

## Platform-Specific Issues

### Apple Silicon (M1/M2/M3) Macs

- Should work out of the box with Metal acceleration
- Ensure you're not running in Rosetta mode
- Check: `uname -m` should return `arm64`

### Intel Macs

- Metal support is available but may be slower
- Accelerate framework is still used for optimization
- Consider using smaller models (base or small)

## Getting More Help

If issues persist:

1. Check the full error output
2. Verify your environment:
   ```bash
   xcode-select -p
   swift --version
   uname -m
   ```

3. Create an issue on GitHub with:
   - Full error messages
   - Output of verification steps above
   - Your macOS version
   - Your Xcode version

## Preventive Measures

To avoid future build issues:

1. Always use the provided scripts:
   - Use `./setup.sh` for initial setup
   - Use `./fix-build.sh` when you encounter errors

2. Keep your development environment updated:
   - Update Xcode regularly
   - Keep Command Line Tools updated: `xcode-select --install`

3. Clean regularly:
   - Run `./fix-build.sh` after pulling changes
   - Clean Xcode build folder weekly if actively developing

4. Don't commit generated files:
   - `whisper.cpp/` (cloned repository)
   - `Sources/WhisperCpp/src/` (generated from whisper.cpp)
   - `Sources/WhisperCpp/include/` (generated from whisper.cpp)
   - `.build/` (Swift build artifacts)
   - `DerivedData/` (Xcode artifacts)

## Understanding the Fixes

### Why rename .c to .cpp?

Swift Package Manager works better with C++ for mixed C/C++ projects. The whisper.cpp project uses both C and C++ code.

### Why add explicit casts?

C allows implicit conversion from `void*` to any pointer type. C++ requires explicit casts. When we rename `.c` files to `.cpp`, the compiler enforces C++ rules.

### Why clean derived data?

Xcode caches absolute paths in derived data. When you move the project or clone it on a different machine, these absolute paths become invalid, causing "Invalid Exclude" errors.
