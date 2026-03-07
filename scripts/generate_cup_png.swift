#!/usr/bin/env swift

import AppKit

// ---------------------------------------------------------------------------
// generate_cup_png.swift – Crop, remove white bg, resize the provided cup image
// ---------------------------------------------------------------------------

let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()
let srcPath = "/Users/void_rsk/Downloads/ChatGPT Image 7 mar 2026, 03_54_41 a.m..png"
let outputDir = repoRoot.appendingPathComponent("Sources/CafeVeloz/Resources")

guard let srcImage = NSImage(contentsOfFile: srcPath) else {
    print("Error: could not load source image at \(srcPath)")
    exit(1)
}

guard let srcCG = srcImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: could not get CGImage")
    exit(1)
}

let srcW = srcCG.width
let srcH = srcCG.height
print("Source: \(srcW)x\(srcH)")

// Step 1: Render to bitmap so we can manipulate pixels
let cs = CGColorSpaceCreateDeviceRGB()
let bytesPerPixel = 4
let bytesPerRow = srcW * bytesPerPixel
var pixels = [UInt8](repeating: 0, count: srcW * srcH * bytesPerPixel)

guard let bitmapCtx = CGContext(data: &pixels, width: srcW, height: srcH,
                                 bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                 space: cs,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    print("Error: bitmap context"); exit(1)
}
bitmapCtx.draw(srcCG, in: CGRect(x: 0, y: 0, width: srcW, height: srcH))

// Step 2: Remove white/near-white background using flood-fill from edges
// First pass: mark background pixels starting from the edges
var isBackground = [Bool](repeating: false, count: srcW * srcH)
var queue: [(Int, Int)] = []

// Seed from all edge pixels that are near-pure-white
for x in 0..<srcW {
    for y in [0, srcH - 1] {
        let i = (y * srcW + x) * bytesPerPixel
        let r = pixels[i], g = pixels[i+1], b = pixels[i+2]
        if r > 245 && g > 245 && b > 245 {
            queue.append((x, y))
            isBackground[y * srcW + x] = true
        }
    }
}
for y in 0..<srcH {
    for x in [0, srcW - 1] {
        let i = (y * srcW + x) * bytesPerPixel
        let r = pixels[i], g = pixels[i+1], b = pixels[i+2]
        if r > 245 && g > 245 && b > 245 && !isBackground[y * srcW + x] {
            queue.append((x, y))
            isBackground[y * srcW + x] = true
        }
    }
}

// BFS flood fill - spread to neighboring bright, low-saturation pixels
var head = 0
while head < queue.count {
    let (px, py) = queue[head]
    head += 1
    for (dx, dy) in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)] {
        let nx = px + dx, ny = py + dy
        guard nx >= 0, nx < srcW, ny >= 0, ny < srcH else { continue }
        let idx = ny * srcW + nx
        guard !isBackground[idx] else { continue }
        let i = idx * bytesPerPixel
        let r = Float(pixels[i]), g = Float(pixels[i+1]), b = Float(pixels[i+2])
        let brightness = (r + g + b) / 3.0
        let saturation = max(r, g, b) - min(r, g, b)
        if brightness > 240 && saturation < 20 {
            isBackground[idx] = true
            queue.append((nx, ny))
        }
    }
}

// Apply: make background fully transparent, edge pixels semi-transparent
for y in 0..<srcH {
    for x in 0..<srcW {
        let idx = y * srcW + x
        let i = idx * bytesPerPixel
        if isBackground[idx] {
            pixels[i] = 0; pixels[i+1] = 0; pixels[i+2] = 0; pixels[i+3] = 0
        } else {
            // Check if near a background pixel (edge softening)
            var nearBg = false
            for (dx, dy) in [(-1,0),(1,0),(0,-1),(0,1),(-2,0),(2,0),(0,-2),(0,2)] {
                let nx = x + dx, ny = y + dy
                if nx >= 0, nx < srcW, ny >= 0, ny < srcH, isBackground[ny * srcW + nx] {
                    nearBg = true; break
                }
            }
            if nearBg {
                let r = Float(pixels[i]), g = Float(pixels[i+1]), b = Float(pixels[i+2])
                let brightness = (r + g + b) / 3.0
                if brightness > 210 {
                    let fade = min(1.0, (brightness - 210.0) / 40.0)
                    pixels[i+3] = UInt8(max(0, Float(pixels[i+3]) * (1.0 - fade * 0.8)))
                }
            }
        }
    }
}

// Step 3: Create new CGImage from modified pixels
guard let modifiedCG = CGContext(data: &pixels, width: srcW, height: srcH,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
        .makeImage() else {
    print("Error: could not create modified image"); exit(1)
}

// Step 4: Find bounding box of non-transparent content
var minX = srcW, maxX = 0, minY = srcH, maxY = 0
for y in 0..<srcH {
    for x in 0..<srcW {
        let i = (y * srcW + x) * bytesPerPixel
        if pixels[i+3] > 10 { // non-transparent
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }
    }
}

// Add small padding
let pad = 8
minX = max(0, minX - pad)
minY = max(0, minY - pad)
maxX = min(srcW - 1, maxX + pad)
maxY = min(srcH - 1, maxY + pad)

let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
print("Crop rect: \(cropRect)")

guard let croppedCG = modifiedCG.cropping(to: cropRect) else {
    print("Error: cropping failed"); exit(1)
}

// Step 5: Resize to target dimensions, maintaining aspect ratio, centering
func resizeToTarget(image: CGImage, targetW: Int, targetH: Int) -> Data? {
    guard let ctx = CGContext(data: nil, width: targetW, height: targetH,
                               bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    let imgW = CGFloat(image.width)
    let imgH = CGFloat(image.height)
    let tW = CGFloat(targetW)
    let tH = CGFloat(targetH)

    let scale = min(tW / imgW, tH / imgH)
    let drawW = imgW * scale
    let drawH = imgH * scale
    let drawX = (tW - drawW) / 2
    let drawY = (tH - drawH) / 2

    ctx.draw(image, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))

    guard let result = ctx.makeImage() else { return nil }
    return NSBitmapImageRep(cgImage: result).representation(using: .png, properties: [:])
}

// Step 6: Export
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for (name, w, h) in [("coffee_cup.png", 180, 200), ("coffee_cup@2x.png", 360, 400)] {
    guard let data = resizeToTarget(image: croppedCG, targetW: w, targetH: h) else {
        print("Failed \(name)"); exit(1)
    }
    try data.write(to: outputDir.appendingPathComponent(name))
    print("Wrote \(name)")
}
print("Done!")
