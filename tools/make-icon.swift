// Makes the app icon from FiestaBoard's own icon (fiesta-icon.png in the
// FiestaBoard repository, MIT): the taco on white, as its apple-touch-icon
// has it, since an app icon may not be transparent.
//
//     swift tools/make-icon.swift <fiesta-icon.png> FiestaBoard/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil)!
let taco = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let size = 1024
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
// Pixel art: no smoothing between its pixels.
ctx.interpolationQuality = .none
let inset = Double(size) * 0.12
ctx.draw(taco, in: CGRect(x: inset, y: inset, width: Double(size) - 2 * inset, height: Double(size) - 2 * inset))
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
