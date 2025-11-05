import Foundation
import CoreImage
import AppKit

/// Utility for generating QR codes
enum QRCodeGenerator {
    /// Generates a QR code image from a string
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - size: The size of the output image (default: 512x512)
    /// - Returns: NSImage of the QR code, or nil if generation fails
    static func generate(from string: String, size: CGSize = CGSize(width: 512, height: 512)) -> NSImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        // Create QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        guard let ciImage = filter.outputImage else {
            return nil
        }

        // Scale up the QR code
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scale = min(scaleX, scaleY)

        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)

        // Convert to NSImage
        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return nsImage
    }

    /// Generates a styled QR code with custom colors
    /// - Parameters:
    ///   - string: The string to encode
    ///   - size: The size of the output image
    ///   - foregroundColor: Color for the QR code pixels
    ///   - backgroundColor: Background color
    /// - Returns: Styled NSImage of the QR code
    static func generateStyled(
        from string: String,
        size: CGSize = CGSize(width: 512, height: 512),
        foregroundColor: NSColor = .black,
        backgroundColor: NSColor = .white
    ) -> NSImage? {
        guard let baseImage = generate(from: string, size: size) else {
            return nil
        }

        // Create a new image with custom colors
        let image = NSImage(size: size)
        image.lockFocus()

        // Draw background
        backgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Draw QR code with foreground color
        if let cgImage = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let context = NSGraphicsContext.current?.cgContext
            context?.setFillColor(foregroundColor.cgColor)

            // Convert black pixels to foreground color
            let ciImage = CIImage(cgImage: cgImage)
            if let filter = CIFilter(name: "CIFalseColor") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(CIColor(color: foregroundColor) ?? CIColor.black, forKey: "inputColor0")
                filter.setValue(CIColor(color: backgroundColor) ?? CIColor.white, forKey: "inputColor1")

                if let output = filter.outputImage {
                    let rep = NSCIImageRep(ciImage: output)
                    let coloredImage = NSImage(size: rep.size)
                    coloredImage.addRepresentation(rep)

                    coloredImage.draw(in: NSRect(origin: .zero, size: size))
                    image.unlockFocus()
                    return image
                }
            }

            // Fallback: draw original
            baseImage.draw(in: NSRect(origin: .zero, size: size))
        }

        image.unlockFocus()
        return image
    }
}
