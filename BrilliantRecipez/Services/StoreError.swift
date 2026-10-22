import Foundation

enum StoreError: LocalizedError {
    case photo, library

    var errorDescription: String? {
        switch self {
        case .photo: "This photo could not be opened. Choose another photo or type your ingredients."
        case .library: "Your recipes could not be saved. Your existing saved file has been kept."
        }
    }
}
