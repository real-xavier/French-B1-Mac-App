import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
let rectangle = NSRect(x: 82, y: 82, width: 860, height: 860)
let shape = NSBezierPath(roundedRect: rectangle, xRadius: 190, yRadius: 190)
NSGradient(starting: NSColor(calibratedRed: 0.22, green: 0.51, blue: 0.79, alpha: 1), ending: NSColor(calibratedRed: 0.10, green: 0.31, blue: 0.57, alpha: 1))!.draw(in: shape, angle: 270)
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 405, weight: .medium), .foregroundColor: NSColor.white, .paragraphStyle: paragraph]
("Fr" as NSString).draw(in: NSRect(x: 82, y: 290, width: 860, height: 500), withAttributes: attributes)
let subAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 94, weight: .semibold), .foregroundColor: NSColor.white.withAlphaComponent(0.88), .paragraphStyle: paragraph]
("B1" as NSString).draw(in: NSRect(x: 82, y: 195, width: 860, height: 125), withAttributes: subAttributes)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("AppIcon-1024.png"))
