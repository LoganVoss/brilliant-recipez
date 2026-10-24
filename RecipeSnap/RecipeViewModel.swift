import SwiftUI
class RecipeViewModel: ObservableObject {
    @Published var recipe: Recipe?
    @Published var errorMessage: String?
    @Published var isLoading = false
    var lastImageData: Data?
    private let apiService = APIService()

    func processPhoto(_ imageData: Data, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.recipe = nil
        }

        let base64String = imageData.base64EncodedString().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base64String.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encode photo."
                self.isLoading = false
                completion(false)
            }
            return
        }

        guard let encodedBase64 = base64String.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to URL-encode photo."
                self.isLoading = false
                completion(false)
            }
            return
        }

        apiService.identifyIngredients(base64Image: encodedBase64) { result in
            switch result {
            case .success(let ingredients):
                self.apiService.generateRecipe(ingredients: ingredients) { result in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        switch result {
                        case .success(let recipe):
                            self.recipe = recipe
                            self.errorMessage = nil
                            completion(true)
                        case .failure(let error):
                            let message: String
                            if (error as NSError).code == 401 {
                                message = "Authentication failed: Please check your API key."
                            } else if (error as NSError).code == 502 {
                                message = "Server error: Please try again later."
                            } else {
                                message = "Failed to generate recipe: \(error.localizedDescription)"
                            }
                            self.errorMessage = message
                            completion(false)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    let message: String
                    if (error as NSError).code == 401 {
                        message = "Authentication failed: Please check your API key."
                    } else if (error as NSError).code == 502 {
                        message = "Server error: Please try again later."
                    } else {
                        message = "Failed to identify ingredients: \(error.localizedDescription)"
                    }
                    self.errorMessage = message
                    completion(false)
                }
            }
        }
    }
}
