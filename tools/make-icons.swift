// Makes the app icons and in-app logo from art/logo-source.png: swift tools/make-icons.swift
//   AppIcon (as drawn), AppIcon-Night (dark squares, same pieces), AppIcon-Mono (all grey),
//   plus Logo and Icon{Classic,Night,Mono} images for the app's own screens.
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let catalog = root.appending(path: "Chess/Assets.xcassets")
guard let source = NSImage(contentsOf: root.appending(path: "art/logo-source.png")),
      let cg = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else { fatalError("no art/logo-source.png") }

/// RGBA pixels of an image, top row first.
func pixels(_ image: CGImage) -> (data: [UInt8], width: Int, height: Int) {
  let w = image.width, h = image.height
  var data = [UInt8](repeating: 0, count: w * h * 4)
  let context = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
  return (data, w, h)
}

func makeImage(_ data: [UInt8], _ w: Int, _ h: Int) -> CGImage {
  var copy = data
  let context = CGContext(data: &copy, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  return context.makeImage()!
}

// The tile: the box of pixels darker than the white page around it.
let (all, width, height) = pixels(cg)
func isPage(_ x: Int, _ y: Int) -> Bool {
  let i = (y * width + x) * 4
  return all[i] > 250 && all[i + 1] > 250 && all[i + 2] > 250
}
let rows = (0..<height).filter { y in stride(from: 0, to: width, by: 4).contains { !isPage($0, y) } }
let cols = (0..<width).filter { x in stride(from: 0, to: height, by: 4).contains { !isPage(x, $0) } }
let tile = CGRect(x: cols.first!, y: rows.first!, width: cols.last! - cols.first! + 1, height: rows.last! - rows.first! + 1)
print("tile:", tile)
// Cropped exactly at the tile: iOS rounds its corners more than the tile does, so no page shows.
let inset = 0.0
let crop = cg.cropping(to: tile.insetBy(dx: inset, dy: inset))!

/// Recolours each pixel: greys (the squares) through `grey`, colours (the pieces) through `colour`.
func recolour(_ image: CGImage, grey: (Double) -> Double, colour: (Double, Double, Double) -> (Double, Double, Double)) -> CGImage {
  var (data, w, h) = pixels(image)
  for i in stride(from: 0, to: data.count, by: 4) {
    let r = Double(data[i]) / 255, g = Double(data[i + 1]) / 255, b = Double(data[i + 2]) / 255
    let spread = max(r, g, b) - min(r, g, b)
    let (nr, ng, nb): (Double, Double, Double)
    if spread < 0.08 {
      let v = grey((r + g + b) / 3)
      (nr, ng, nb) = (v, v, v)
    } else {
      (nr, ng, nb) = colour(r, g, b)
    }
    data[i] = UInt8(max(0, min(255, nr * 255)))
    data[i + 1] = UInt8(max(0, min(255, ng * 255)))
    data[i + 2] = UInt8(max(0, min(255, nb * 255)))
  }
  return makeImage(data, w, h)
}

let classic = crop
// Night: light squares become graphite, the pieces keep their colour.
let night = recolour(crop, grey: { 0.12 + (1 - $0) * 1.4 }, colour: { ($0, $1, $2) })
// Mono: everything grey, the pieces a soft mid grey.
let mono = recolour(crop, grey: { $0 }, colour: { r, g, b in
  let l = 0.2126 * r + 0.7152 * g + 0.0722 * b
  let v = 0.35 + l * 0.25
  return (v, v, v)
})

func write(_ image: CGImage, side: Int, to url: URL) {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  NSGraphicsContext.current?.imageInterpolation = .high
  NSImage(cgImage: image, size: .zero).draw(in: NSRect(x: 0, y: 0, width: side, height: side))
  NSGraphicsContext.restoreGraphicsState()
  try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

func appIcon(_ name: String, _ image: CGImage) {
  let folder = catalog.appending(path: "\(name).appiconset")
  try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  write(image, side: 1024, to: folder.appending(path: "icon.png"))
  try! #"{"images":[{"filename":"icon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}"#
    .write(to: folder.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
}

func imageSet(_ name: String, _ image: CGImage) {
  let folder = catalog.appending(path: "\(name).imageset")
  try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  write(image, side: 512, to: folder.appending(path: "\(name).png"))
  try! #"{"images":[{"filename":"\#(name).png","idiom":"universal"}],"info":{"author":"xcode","version":1}}"#
    .write(to: folder.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
}

appIcon("AppIcon", classic)
appIcon("AppIcon-Night", night)
appIcon("AppIcon-Mono", mono)
imageSet("Logo", classic)
imageSet("IconClassic", classic)
imageSet("IconNight", night)
imageSet("IconMono", mono)
print("done")
