#!/usr/bin/env swift

import Cocoa
import Foundation

// Icon generator for Kalam app bundle.
// Creates a waveform-inspired app icon with subtle Devanagari कलम accent

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let context = NSGraphicsContext.current!.cgContext

    // Background - rounded square with gradient
    let cornerRadius = size * 0.22
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                               xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background (purple to darker purple)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.58, green: 0.52, blue: 0.72, alpha: 1.0),  // #948BAB - lighter purple
        NSColor(red: 0.45, green: 0.40, blue: 0.58, alpha: 1.0),  // #736694 - mid purple
        NSColor(red: 0.35, green: 0.30, blue: 0.48, alpha: 1.0)   // #594D7A - darker purple
    ], atLocations: [0.0, 0.5, 1.0], colorSpace: .deviceRGB)!

    gradient.draw(in: bgPath, angle: -45)

    // Subtle inner shadow/glow
    context.saveGState()
    bgPath.addClip()

    let shadowColor = NSColor.black.withAlphaComponent(0.2)
    let shadow = NSShadow()
    shadow.shadowColor = shadowColor
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.02)
    shadow.shadowBlurRadius = size * 0.05
    shadow.set()

    NSColor.clear.setFill()
    bgPath.fill()
    context.restoreGState()

    // Draw waveform bars (shifted up slightly to make room for कलम)
    let waveformColor = NSColor.white
    let barCount = 5
    let totalWidth = size * 0.55
    let barWidth = size * 0.08
    let spacing = (totalWidth - (CGFloat(barCount) * barWidth)) / CGFloat(barCount - 1)
    let startX = (size - totalWidth) / 2
    let centerY = size * 0.54  // slightly above center

    // Bar heights (normalized) - creating a waveform pattern
    let heights: [CGFloat] = [0.35, 0.65, 1.0, 0.65, 0.35]
    let maxBarHeight = size * 0.40

    waveformColor.setFill()

    for i in 0..<barCount {
        let barHeight = heights[i] * maxBarHeight
        let x = startX + CGFloat(i) * (barWidth + spacing)
        let y = centerY - barHeight / 2

        let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
        barPath.fill()
    }

    // Draw कलम (Devanagari) below the waveform — only at larger icon sizes
    if size >= 128 {
        let devanagariText = "कलम" as NSString
        let fontSize = size * 0.12
        let font = NSFont(name: "Devanagari Sangam MN", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(0.6)
        ]
        let textSize = devanagariText.size(withAttributes: textAttributes)
        let textX = (size - textSize.width) / 2
        let textY = size * 0.18 - textSize.height / 2  // below waveform
        devanagariText.draw(at: NSPoint(x: textX, y: textY), withAttributes: textAttributes)
    }

    // Add subtle highlight at top
    context.saveGState()
    bgPath.addClip()

    let highlightGradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.15),
        NSColor.white.withAlphaComponent(0.0)
    ])!

    let highlightRect = NSRect(x: 0, y: size * 0.5, width: size, height: size * 0.5)
    highlightGradient.draw(in: highlightRect, angle: 90)
    context.restoreGState()

    image.unlockFocus()

    return image
}

func createIconSet(outputPath: String) {
    let sizes: [(CGFloat, String, Int)] = [
        (16, "16x16", 1),
        (32, "16x16@2x", 2),
        (32, "32x32", 1),
        (64, "32x32@2x", 2),
        (128, "128x128", 1),
        (256, "128x128@2x", 2),
        (256, "256x256", 1),
        (512, "256x256@2x", 2),
        (512, "512x512", 1),
        (1024, "512x512@2x", 2)
    ]

    let iconsetPath = "\(outputPath)/AppIcon.iconset"

    // Create iconset directory
    try? FileManager.default.createDirectory(atPath: iconsetPath,
                                              withIntermediateDirectories: true)

    for (size, name, _) in sizes {
        let icon = createIcon(size: size)
        let filename = "icon_\(name).png"
        let filePath = "\(iconsetPath)/\(filename)"

        if let tiffData = icon.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: filePath))
            print("  Created \(filename)")
        }
    }

    // Also save a 1024x1024 PNG for App Store
    let appStoreIcon = createIcon(size: 1024)
    let appStoreIconPath = "\(outputPath)/AppIcon-1024.png"
    if let tiffData = appStoreIcon.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: appStoreIconPath))
        print("  Created AppIcon-1024.png (App Store)")
    }

    // Convert to icns using iconutil
    let icnsPath = "\(outputPath)/AppIcon.icns"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("  Created AppIcon.icns")
            // Clean up iconset folder
            try? FileManager.default.removeItem(atPath: iconsetPath)
        } else {
            print("  Warning: iconutil failed, keeping iconset folder")
        }
    } catch {
        print("  Error running iconutil: \(error)")
    }
}

// Main
let outputPath: String
if CommandLine.arguments.count > 1 {
    outputPath = CommandLine.arguments[1]
} else {
    outputPath = "."
}

print("🎨 Generating Kalam app icon...")
createIconSet(outputPath: outputPath)
print("✅ Icon generated!")
