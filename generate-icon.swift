#!/usr/bin/env swift
import AppKit
import CoreGraphics

/// ServerPulse — Minimalist Icon Generator
/// Clean geometric octopus silhouette with pulse line
/// Design: large dome head, 4 clean tentacles, ECG line, minimal eyes

func generateIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size / 512.0
    let cx = size / 2.0

    // ── Background: rounded rect with dark gradient ──
    let inset = size * 0.04
    let bgRect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cr = size * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cr, cornerHeight: cr, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let bgColors = [
        CGColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1.0),
        CGColor(red: 0.11, green: 0.10, blue: 0.18, alpha: 1.0)
    ]
    let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: bgColors as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0), options: [])

    // ── Tentacles (drawn BEHIND the head) ──
    // 4 symmetrical tentacles, thick, smooth bezier curves
    let pinkMain = CGColor(red: 0.85, green: 0.35, blue: 0.45, alpha: 1.0)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Tentacle data: (startX, startY, cp1X, cp1Y, cp2X, cp2Y, endX, endY)
    // Coordinates in 512-space, Y = from top
    let tentacles: [(sx: CGFloat, sy: CGFloat, c1x: CGFloat, c1y: CGFloat,
                     c2x: CGFloat, c2y: CGFloat, ex: CGFloat, ey: CGFloat)] = [
        // Left outer: flows left and down with gentle S-curve
        (150, 290, 90, 330, 70, 400, 105, 440),
        // Left inner: flows down-left
        (210, 310, 170, 365, 155, 420, 185, 455),
        // Right inner: mirror of left inner
        (302, 310, 342, 365, 357, 420, 327, 455),
        // Right outer: mirror of left outer
        (362, 290, 422, 330, 442, 400, 407, 440),
    ]

    for t in tentacles {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: t.sx * s, y: (512 - t.sy) * s))
        path.addCurve(
            to: CGPoint(x: t.ex * s, y: (512 - t.ey) * s),
            control1: CGPoint(x: t.c1x * s, y: (512 - t.c1y) * s),
            control2: CGPoint(x: t.c2x * s, y: (512 - t.c2y) * s)
        )
        ctx.setStrokeColor(pinkMain)
        ctx.setLineWidth(26 * s)
        ctx.addPath(path)
        ctx.strokePath()
    }

    // ── Head (mantle) — large dome, filled with gradient ──
    let headCX: CGFloat = 256
    let headCY: CGFloat = 200
    let headRX: CGFloat = 140  // horizontal radius
    let headRY: CGFloat = 115  // vertical radius

    let headRect = CGRect(
        x: (headCX - headRX) * s,
        y: (512 - headCY - headRY) * s,
        width: headRX * 2 * s,
        height: headRY * 2 * s
    )

    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4 * s), blur: 20 * s,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))

    let headColors = [
        CGColor(red: 0.95, green: 0.48, blue: 0.56, alpha: 1.0),
        CGColor(red: 0.75, green: 0.28, blue: 0.38, alpha: 1.0),
    ]
    let headGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: headColors as CFArray, locations: [0.0, 1.0])!
    ctx.addEllipse(in: headRect)
    ctx.clip()
    ctx.drawLinearGradient(headGrad,
                           start: CGPoint(x: cx, y: headRect.maxY),
                           end: CGPoint(x: cx, y: headRect.minY), options: [])
    ctx.restoreGState()

    // Reset clip to background
    ctx.resetClip()
    ctx.addPath(bgPath)
    ctx.clip()

    // ── Eyes — clean white ovals with dark pupils ──
    let eyeW: CGFloat = 22 * s
    let eyeH: CGFloat = 26 * s
    let leftEyeX: CGFloat = 222 * s
    let rightEyeX: CGFloat = 290 * s
    let eyeY: CGFloat = (512 - 200) * s

    // White sclera
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
    ctx.fillEllipse(in: CGRect(x: leftEyeX - eyeW, y: eyeY - eyeH,
                                width: eyeW * 2, height: eyeH * 2))
    ctx.fillEllipse(in: CGRect(x: rightEyeX - eyeW, y: eyeY - eyeH,
                                width: eyeW * 2, height: eyeH * 2))

    // Dark pupils
    let pr: CGFloat = 12 * s
    ctx.setFillColor(CGColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: leftEyeX - pr + 2 * s, y: eyeY - pr - 1 * s,
                                width: pr * 2, height: pr * 2))
    ctx.fillEllipse(in: CGRect(x: rightEyeX - pr + 2 * s, y: eyeY - pr - 1 * s,
                                width: pr * 2, height: pr * 2))

    // Highlight dots
    let hr: CGFloat = 4.5 * s
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.92))
    ctx.fillEllipse(in: CGRect(x: leftEyeX + 5 * s - hr, y: eyeY + 5 * s - hr,
                                width: hr * 2, height: hr * 2))
    ctx.fillEllipse(in: CGRect(x: rightEyeX + 5 * s - hr, y: eyeY + 5 * s - hr,
                                width: hr * 2, height: hr * 2))

    // ── Pulse / ECG line across the forehead ──
    let pulsePath = CGMutablePath()
    let py: CGFloat = (512 - 150) * s

    pulsePath.move(to: CGPoint(x: 145 * s, y: py))
    pulsePath.addLine(to: CGPoint(x: 222 * s, y: py))
    pulsePath.addLine(to: CGPoint(x: 234 * s, y: py + 16 * s))
    pulsePath.addLine(to: CGPoint(x: 246 * s, y: py - 30 * s))
    pulsePath.addLine(to: CGPoint(x: 258 * s, y: py + 20 * s))
    pulsePath.addLine(to: CGPoint(x: 270 * s, y: py - 8 * s))
    pulsePath.addLine(to: CGPoint(x: 280 * s, y: py))
    pulsePath.addLine(to: CGPoint(x: 367 * s, y: py))

    // Glow layer
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 0.25))
    ctx.setLineWidth(12 * s)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.addPath(pulsePath)
    ctx.strokePath()
    ctx.restoreGState()

    // Main pulse stroke
    ctx.setStrokeColor(CGColor(red: 0.30, green: 0.90, blue: 0.55, alpha: 0.95))
    ctx.setLineWidth(4 * s)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.addPath(pulsePath)
    ctx.strokePath()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let resized = NSImage(size: NSSize(width: size, height: size))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    resized.unlockFocus()

    guard let tiffData = resized.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for size \(size)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("  \(size)x\(size) -> \(path)")
    } catch {
        print("Error: \(error)")
    }
}

// --- Main ---
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/ServerPulse.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: outputDir)
try! fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

print("Generating minimalist ServerPulse icon...")
let masterImage = generateIcon(size: 1024)

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for entry in sizes {
    savePNG(masterImage, to: "\(outputDir)/\(entry.name).png", size: entry.px)
}

print("Done! Icon set at: \(outputDir)")
