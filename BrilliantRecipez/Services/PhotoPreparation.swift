import UIKit
import ImageIO

enum PhotoPreparation {
    /// Downsampling avoids decoding the full-resolution camera image into memory.
    /// Re-encoding a new image omits GPS and other original photo metadata.
    static func jpeg(from data: Data) throws -> Data {
        guard data.count <= 60_000_000,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary),
              let jpeg = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.8)
        else { throw StoreError.photo }
        return jpeg
    }
}
