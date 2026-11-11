// Renders the three app icons from the cburnett knight: swift tools/make-icons.swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let catalog = root.appending(path: "Chess/Assets.xcassets")
let knight = catalog.appending(path: "cburnett/wN.imageset/wN.svg")

struct Style { let name: String; let ground: NSColor; let tint: NSColor? }
let styles = [
  Style(name: "AppIcon", ground: NSColor(white: 0.996, alpha: 1), tint: nil),
  Style(name: "AppIcon-Night", ground: NSColor(srgbRed: 0.149, green: 0.149, blue: 0.149, alpha: 1), tint: nil),
  Style(name: "AppIcon-Mono", ground: NSColor(srgbRed: 0.902, green: 0.902, blue: 0.902, alpha: 1), tint: NSColor(white: 0.45, alpha: 1)),
]

guard let svg = NSImage(contentsOf: knight) else { fatalError("cannot read \(knight.path)") }
let side = 1024
for style in styles {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  style.ground.setFill()
  NSRect(x: 0, y: 0, width: side, height: side).fill()
  let inset = CGFloat(side) * 0.17
  let box = NSRect(x: inset, y: inset * 0.9, width: CGFloat(side) - inset * 2, height: CGFloat(side) - inset * 2)
  if let tint = style.tint {
    let tinted = NSImage(size: box.size, flipped: false) { rect in
      svg.draw(in: rect)
      tint.set()
      rect.fill(using: .sourceAtop)
      return true
    }
    tinted.draw(in: box)
  } else {
    svg.draw(in: box)
  }
  NSGraphicsContext.restoreGraphicsState()
  let folder = catalog.appending(path: "\(style.name).appiconset")
  try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  try! rep.representation(using: .png, properties: [:])!.write(to: folder.appending(path: "icon.png"))
  let contents = #"{"images":[{"filename":"icon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}"#
  try! contents.write(to: folder.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
  print(folder.lastPathComponent)
}
