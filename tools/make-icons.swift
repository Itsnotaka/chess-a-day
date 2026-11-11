// Renders the Icon Composer source and the shared in-app branding: swift tools/make-icons.swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let catalog = root.appending(path: "Chess/Assets.xcassets")
let sourceURL = root.appending(path: "art/logo-source.png")
let developerDirectory = Process()
let developerOutput = Pipe()
developerDirectory.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
developerDirectory.arguments = ["--print-path"]
developerDirectory.standardOutput = developerOutput
try developerDirectory.run()
developerDirectory.waitUntilExit()
guard developerDirectory.terminationStatus == 0,
      let developerPath = String(data: developerOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
  fatalError("Could not locate Xcode")
}
let renderer = Process()
renderer.executableURL = URL(fileURLWithPath: developerPath.trimmingCharacters(in: .whitespacesAndNewlines))
  .deletingLastPathComponent().appending(path: "Applications/Icon Composer.app/Contents/Executables/ictool")
renderer.arguments = [root.appending(path: "Chess/AppIcon.icon").path, "--export-image",
                      "--output-file", sourceURL.path, "--platform", "iOS", "--rendition", "Default",
                      "--width", "1024", "--height", "1024", "--scale", "1"]
try renderer.run()
renderer.waitUntilExit()
guard renderer.terminationStatus == 0,
      let source = NSImage(contentsOf: sourceURL),
      let cg = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  fatalError("Could not render AppIcon.icon")
}

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

let classic = cg
// Night: light squares become graphite, the pieces keep their colour.
let night = recolour(cg, grey: { 0.12 + (1 - $0) * 1.4 }, colour: { ($0, $1, $2) })
// Mono: everything grey, the pieces a soft mid grey.
let mono = recolour(cg, grey: { $0 }, colour: { r, g, b in
  let l = 0.2126 * r + 0.7152 * g + 0.0722 * b
  let v = 0.35 + l * 0.25
  return (v, v, v)
})

func write(_ image: CGImage, side: Int, to url: URL, background: NSColor = .white) {
  let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  let rect = CGRect(x: 0, y: 0, width: side, height: side)
  context.setFillColor(background.cgColor)
  context.fill(rect)
  context.interpolationQuality = .high
  context.draw(image, in: rect)
  let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
  try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

func appIcon(_ name: String, _ image: CGImage) {
  let folder = catalog.appending(path: "\(name).appiconset")
  try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  write(image, side: 1024, to: folder.appending(path: "icon.png"), background: name == "AppIcon-Night" ? NSColor(white: 0.12, alpha: 1) : .white)
  try! #"{"images":[{"filename":"icon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}"#
    .write(to: folder.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
}

func imageSet(_ name: String, _ image: CGImage) {
  let folder = catalog.appending(path: "\(name).imageset")
  try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  write(image, side: 512, to: folder.appending(path: "\(name).png"), background: name == "IconNight" ? NSColor(white: 0.12, alpha: 1) : .white)
  try! #"{"images":[{"filename":"\#(name).png","idiom":"universal"}],"info":{"author":"xcode","version":1}}"#
    .write(to: folder.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
}

appIcon("AppIcon-Night", night)
appIcon("AppIcon-Mono", mono)
imageSet("Logo", classic)
imageSet("IconClassic", classic)
imageSet("IconNight", night)
imageSet("IconMono", mono)
print("done")
