import Foundation
import ImageIO
import Vision
import RecipeCore

struct LocalPhotoService: Sendable {
    func identifyIngredients(jpegData: Data) async throws -> [String] {
        try Task.checkCancellation()
        if AppleRecipeService.supportsImageInput {
            do {
                return try await AppleRecipeService().identifyIngredients(jpegData: jpegData)
            } catch let error as AppleRecipeError {
                switch error {
                case .imageInputUnavailable, .availability:
                    break // A model can become unavailable between its capability check and request.
                default:
                    throw error
                }
            }
        }
        return try await visionSuggestions(jpegData: jpegData)
    }

    /// Vision's synchronous work runs away from the main actor. Cancellation is forwarded
    /// to the worker and checked between requests, so canceled work never updates the UI.
    func visionSuggestions(jpegData: Data) async throws -> [String] {
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard !jpegData.isEmpty, jpegData.count <= 8 * 1_024 * 1_024,
                  let source = CGImageSourceCreateWithData(jpegData as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw StoreError.photo }
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            let orientationValue = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
            let orientation = CGImagePropertyOrientation(rawValue: orientationValue) ?? .up
            let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
            let classifier = VNClassifyImageRequest()
            let text = VNRecognizeTextRequest()
            text.recognitionLevel = .accurate
            text.recognitionLanguages = ["en-US"]
            text.usesLanguageCorrection = true
            do {
                try handler.perform([classifier])
                try Task.checkCancellation()
                try handler.perform([text])
                try Task.checkCancellation()
            } catch {
                if Task.isCancelled || error is CancellationError { throw CancellationError() }
                throw StoreError.photo
            }
            let classifications = (classifier.results ?? []).filter { $0.confidence >= 0.7 }.map(\.identifier)
            let labels = (text.results ?? []).compactMap { observation -> String? in
                guard let candidate = observation.topCandidates(1).first, candidate.confidence >= 0.85 else { return nil }
                return candidate.string
            }
            return FoodSuggestionFilter.suggestions(classifications: classifications, labels: labels)
        }
        return try await withTaskCancellationHandler {
            let result = try await worker.value
            try Task.checkCancellation()
            return result
        } onCancel: {
            worker.cancel()
        }
    }
}
