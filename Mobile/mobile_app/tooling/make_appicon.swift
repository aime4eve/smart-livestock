// Smart Livestock app icon generator.
// Usage: swift make_appicon.swift <output-dir>
// Renders:
//   app_icon_master_1024.png        1024x1024, no alpha (iOS)
//   app_icon_adaptive_fg_1024.png   1024x1024, transparent bg, head at 62% (Android adaptive fg)
//   preview_128.png / preview_60.png  small-size readability checks
//
// Design: geometric cream cow head with ivory horns/ears and a yellow ear
// tag (the "smart livestock" symbol) on a brand-green vertical gradient.
//
// ⚠️ CGBitmapContext is y-up (origin bottom-left). All drawing below uses
// VISUAL coordinates (y measured from TOP) via the V()/rectV()/ellipseV()
// helpers. Never pass raw visual y to CGContext calls.

import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

let S: CGFloat = 1024

// MARK: - Palette (app brand: primary #2F6B3B, primaryDark #244F2D)
let cGreenTop = hex(0x4E9C61)
let cGreenBottom = hex(0x244F2D)
let cCream = hex(0xF7F2E2)
let cCreamShade = hex(0xE3D8BA)
let cIvory = hex(0xEFE4C6)
let cMuzzle = hex(0xEFE6CB)
let cDark = hex(0x33402F)
let cTag = hex(0xFFC93C)
let cTagHole = hex(0x8A6A14)

func hex(_ v: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

// MARK: - Visual-coordinate helpers (y from TOP of the 1024 canvas)
func pV(_ x: CGFloat, _ yTop: CGFloat) -> CGPoint { CGPoint(x: x, y: S - yTop) }
func rectV(_ x: CGFloat, _ yTop: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: S - yTop - h, width: w, height: h)
}
func ellipseV(_ cx: CGFloat, _ cyTop: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGRect {
    CGRect(x: cx - rx, y: S - cyTop - ry, width: rx * 2, height: ry * 2)
}
func circleV(_ cx: CGFloat, _ cyTop: CGFloat, _ r: CGFloat) -> CGRect { ellipseV(cx, cyTop, r, r) }

// MARK: - Background
func drawBackground(_ ctx: CGContext) {
    let colors = [cGreenTop, cGreenBottom] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    // vertical: visual top -> visual bottom
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])
    // soft radial light, top-left
    let light = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [hex(0xFFFFFF, 0.20), hex(0xFFFFFF, 0)] as CFArray,
                           locations: [0, 1])!
    ctx.drawRadialGradient(light, startCenter: pV(300, 260), startRadius: 0,
                           endCenter: pV(300, 260), endRadius: 760, options: [])
}

// MARK: - Horns (mirrored; drawn behind the head)
func drawHorn(_ ctx: CGContext, mirror: Bool) {
    func X(_ x: CGFloat) -> CGFloat { mirror ? S - x : x }
    ctx.setFillColor(cIvory)
    let p = CGMutablePath()
    // outer edge: root -> tip
    p.move(to: pV(X(340), 392))
    p.addCurve(to: pV(X(234), 196),
               control1: pV(X(276), 318), control2: pV(X(238), 250))
    // rounded tip
    p.addQuadCurve(to: pV(X(300), 182), control: pV(X(258), 166))
    // inner edge: tip -> root
    p.addCurve(to: pV(X(420), 358),
               control1: pV(X(322), 236), control2: pV(X(378), 292))
    p.addQuadCurve(to: pV(X(340), 392), control: pV(X(378), 380))
    p.closeSubpath()
    ctx.addPath(p)
    ctx.fillPath()
}

// MARK: - Ears (mirrored; drawn in front of the head)
func drawEar(_ ctx: CGContext, mirror: Bool) {
    func X(_ x: CGFloat) -> CGFloat { mirror ? S - x : x }
    ctx.saveGState()
    ctx.translateBy(x: X(298), y: S - 448)
    ctx.rotate(by: mirror ? 0.32 : -0.32)
    ctx.setFillColor(cCream)
    ctx.fillEllipse(in: CGRect(x: -102, y: -54, width: 204, height: 108))
    ctx.setFillColor(cCreamShade)
    ctx.fillEllipse(in: CGRect(x: -60, y: -28, width: 120, height: 56))
    ctx.restoreGState()
}

// MARK: - Yellow ear tag on the viewer-left ear
func drawEarTag(_ ctx: CGContext) {
    // hanger loop
    ctx.setStrokeColor(cTagHole)
    ctx.setLineWidth(9)
    ctx.strokeEllipse(in: circleV(258, 492, 14))
    // tag body
    let tag = CGMutablePath()
    let r: CGFloat = 17
    tag.addRoundedRect(in: rectV(228, 500, 60, 82), cornerWidth: r, cornerHeight: r, transform: .identity)
    ctx.setFillColor(cTag)
    ctx.addPath(tag)
    ctx.fillPath()
    // punch hole
    ctx.setFillColor(hex(0x244F2D))
    ctx.fillEllipse(in: ellipseV(258, 520, 8, 8))
}

// MARK: - Head + face
func drawHead(_ ctx: CGContext) {
    // main head: big rounded form, slightly wider at the brow
    let head = CGMutablePath()
    head.addRoundedRect(in: rectV(302, 292, 420, 520), cornerWidth: 168, cornerHeight: 168, transform: .identity)
    ctx.setFillColor(cCream)
    ctx.addPath(head)
    ctx.fillPath()

    // muzzle
    ctx.setFillColor(cMuzzle)
    ctx.fillEllipse(in: ellipseV(512, 668, 148, 100))
    // nostrils
    ctx.setFillColor(hex(0x33402F, 0.72))
    ctx.fillEllipse(in: ellipseV(458, 664, 16, 21))
    ctx.fillEllipse(in: ellipseV(566, 664, 16, 21))
    // eyes
    ctx.setFillColor(cDark)
    ctx.fillEllipse(in: circleV(434, 508, 21))
    ctx.fillEllipse(in: circleV(590, 508, 21))
    // brow tuft: small hair curl on the forehead for character
    ctx.setStrokeColor(cCreamShade)
    ctx.setLineWidth(14)
    ctx.setLineCap(.round)
    let tuft = CGMutablePath()
    tuft.move(to: pV(512, 372))
    tuft.addQuadCurve(to: pV(560, 412), control: pV(516, 400))
    ctx.addPath(tuft)
    ctx.strokePath()
}

// MARK: - Composition
func render(size: CGFloat, scale: CGFloat, includeBackground: Bool, hasAlpha: Bool) -> CGImage? {
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size),
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: (hasAlpha
                            ? CGImageAlphaInfo.premultipliedLast.rawValue
                            : CGImageAlphaInfo.noneSkipLast.rawValue))!
    // scale the 1024 design space into the target bitmap
    let k = size / S
    ctx.scaleBy(x: k, y: k)
    // composite a "unit" at reduced scale, centered (adaptive foreground)
    if scale < 1 {
        let pad = S * (1 - scale) / 2
        ctx.translateBy(x: pad, y: pad)
        ctx.scaleBy(x: scale, y: scale)
    }
    if includeBackground { drawBackground(ctx) }
    drawHorn(ctx, mirror: false)
    drawHorn(ctx, mirror: true)
    drawHead(ctx)
    drawEar(ctx, mirror: false)
    drawEar(ctx, mirror: true)
    drawEarTag(ctx)
    return ctx.makeImage()
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("cannot create destination \(path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("write failed \(path)") }
    print("wrote \(path)")
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// iOS master: full bleed, no alpha
if let img = render(size: S, scale: 1, includeBackground: true, hasAlpha: false) {
    writePNG(img, to: "\(outDir)/app_icon_master_1024.png")
}
// Android adaptive foreground: transparent, content at 62% safe-zone scale
if let img = render(size: S, scale: 0.62, includeBackground: false, hasAlpha: true) {
    writePNG(img, to: "\(outDir)/app_icon_adaptive_fg_1024.png")
}
// readability previews
if let img = render(size: 128, scale: 1, includeBackground: true, hasAlpha: false) {
    writePNG(img, to: "\(outDir)/preview_128.png")
}
if let img = render(size: 60, scale: 1, includeBackground: true, hasAlpha: false) {
    writePNG(img, to: "\(outDir)/preview_60.png")
}
