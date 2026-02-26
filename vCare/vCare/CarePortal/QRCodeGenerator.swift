import CoreImage.CIFilterBuiltins
import SwiftUI

enum QRCodeGenerator {
    static func generate(from string: String, size: CGFloat = 220) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), from: outputImage.extent) {
            return Image(decorative: cgImage, scale: 1, orientation: .up)
        }
        return Image(systemName: "qrcode")
    }
}
