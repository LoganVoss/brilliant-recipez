import Foundation
class APIService {
    // Supply your own key in the local Xcode Run scheme environment. Never commit a key.
    private let apiKey = ProcessInfo.processInfo.environment["XAI_API_KEY"] ?? ""
    private let chatBaseURL = "https://api.x.ai/v1/chat/completions"
    private let imageBaseURL = "https://api.x.ai/v1/images/generations"
    private var lastUsedCulture: String?
    private var lastRecipeTitle: String?

    func identifyIngredients(base64Image: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !apiKey.isEmpty else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key is missing. Please try again."])
            print("Configuration Error: \(error)")
            completion(.failure(error))
            return
        }

        guard !base64Image.isEmpty else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data. Please try again."])
            print("Validation Error: Empty base64 image string")
            completion(.failure(error))
            return
        }

        if base64Image.count > 10_000_000 {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image size is too large. Please use a smaller image."])
            print("Validation Error: Base64 image string too large (\(base64Image.count) characters)")
            completion(.failure(error))
            return
        }

        let prompt = """
        Identify the ingredients in this photo with 90% confidence that they are physically present. Accurately identify any visible text on bottles, cans, jars, and packaging. Only list ingredients that are clearly visible in the image or explicitly labeled on packaging. Return a JSON object with an 'ingredients' key containing an array of ingredient names.
        """
        let payload: [String: Any] = [
            "model": "grok-2-vision-1212",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.5,
            "stream": false
        ]

        makeAPIRequest(url: chatBaseURL, payload: payload, retryCount: 0) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    if let rawJSON = String(data: data, encoding: .utf8) {
                        print("Ingredient API Response: \(rawJSON)")
                    }
                    let response = try JSONDecoder().decode(IngredientApiResponse.self, from: data)
                    guard let content = response.choices.first?.message.content else {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ingredients found in response. Please try again."])
                        print("Response Error: No content in API response")
                        completion(.failure(error))
                        return
                    }

                    if let contentData = content.data(using: .utf8),
                       let contentJSON = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                       let ingredients = contentJSON["ingredients"] as? [String] {
                        let capitalizedIngredients = ingredients.map { $0.capitalized }
                        completion(.success(capitalizedIngredients))
                    } else {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse ingredients from response. Please try again."])
                        print("Parsing Error: Content is not a valid JSON object with 'ingredients' key")
                        completion(.failure(error))
                    }
                } catch {
                    if let errorResponse = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        let errorMessage = errorResponse.error.message.isEmpty ? "Failed to identify ingredients. Please try again." : errorResponse.error.message
                        let error = NSError(domain: "", code: errorResponse.error.code ?? -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("API Error: \(error) - \(errorMessage)")
                        completion(.failure(error))
                    } else {
                        print("Decoding Error: \(error)")
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse ingredient response: \(error.localizedDescription). Please try again."])
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                print("Ingredient API Error: \(error)")
                let error = NSError(domain: "", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: "Failed to identify ingredients: \(error.localizedDescription). Please try again."])
                completion(.failure(error))
            }
        }
    }

    func generateRecipe(ingredients: [String], completion: @escaping (Result<Recipe, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key is missing. Please try again."])
            print("Configuration Error: \(error)")
            completion(.failure(error))
            return
        }

        let ingredientList = ingredients.joined(separator: ", ")
        let cultureExclusion = lastUsedCulture != nil ? " (do not use \(lastUsedCulture!) cuisine)" : ""
        let titleExclusion = lastRecipeTitle != nil ? " (do not generate a recipe similar to \(lastRecipeTitle!))" : ""
        let textPrompt = """
        Using EXACTLY the following explicitly identified ingredients from the photo: \(ingredientList), plus ONLY the optional basic staples (olive oil, salt, pepper, water), generate a delicious recipe with a subtle cultural twist\(cultureExclusion)\(titleExclusion). The recipe MUST NOT include ANY ingredients not explicitly listed in the provided ingredients or the allowed staples (olive oil, salt, pepper, water), even if they are typical for the cultural style. The cultural twist should only influence the preparation style or flavor profile, not the ingredient list. The recipe must appeal to a broad audience while incorporating a hint of a culinary culture in its style, without being overly culture-specific. The recipe must not include any ingredients not explicitly listed in the provided ingredients or shown in the photo, except the staples. Exclude any microwave cooking methods. The recipe should include:
        - A title
        - A short, exciting description (1-2 sentences) to entice the user
        - A list of ingredients (as a single string, with staples listed as olive oil, salt, pepper, water)
        - Detailed preparation instructions (as an array of individual steps)
        Return the response as a JSON object with 'title', 'description', 'ingredients', 'instructions', and 'culture' fields, where 'culture' identifies the culinary culture (e.g., 'Italian-inspired', 'Mexican-inspired', 'Japanese-inspired').
        """
        let textPayload: [String: Any] = [
            "model": "grok-2-vision-1212",
            "messages": [
                [
                    "role": "user",
                    "content": textPrompt
                ]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.7,
            "stream": false
        ]

        makeAPIRequest(url: chatBaseURL, payload: textPayload, retryCount: 0) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    if let rawJSON = String(data: data, encoding: .utf8) {
                        print("Recipe Text API Response: \(rawJSON)")
                    }
                    let textResponse = try JSONDecoder().decode(RecipeTextResponse.self, from: data)
                    guard let contentString = textResponse.choices.first?.message.content,
                          let contentData = contentString.data(using: .utf8) else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid content format"))
                    }
                    let partialRecipe = try JSONDecoder().decode(PartialRecipe.self, from: contentData)

                    let allowedIngredients = Set(ingredients.map { $0.lowercased() } + ["olive oil", "salt", "pepper", "water"])
                    let recipeIngredients = partialRecipe.ingredients.lowercased()
                        .components(separatedBy: ", ")
                        .flatMap { $0.split(separator: " and ").map { String($0) } }
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    if recipeIngredients.contains(where: { !allowedIngredients.contains($0) }) {
                        print("Invalid ingredients detected: \(recipeIngredients.filter { !allowedIngredients.contains($0) })")
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Generated recipe contains invalid ingredients. Please try again."])
                        completion(.failure(error))
                        return
                    }

                    if let culture = partialRecipe.culture {
                        self.lastUsedCulture = culture
                    }
                    self.lastRecipeTitle = partialRecipe.title

                    let imagePrompt = """
                    A realistic, appetizing dish of \(partialRecipe.title), beautifully plated with natural lighting, authentic textures, and a delightful presentation that looks as if it were photographed in a real kitchen, avoiding any artificial or computer-generated effects. The dish must ONLY include the following ingredients: \(partialRecipe.ingredients). Do not include any ingredients not explicitly listed.
                    """
                    let imagePayload: [String: Any] = [
                        "model": "grok-2-image-1212",
                        "prompt": imagePrompt,
                        "n": 1,
                        "response_format": "b64_json"
                    ]

                    self.makeAPIRequest(url: self.imageBaseURL, payload: imagePayload, retryCount: 0) { (result: Result<Data, Error>) in
                        switch result {
                        case .success(let imageData):
                            do {
                                if let rawJSON = String(data: imageData, encoding: .utf8) {
                                    print("Recipe Image API Response: \(rawJSON)")
                                }
                                let imageResponse = try JSONDecoder().decode(ImageResponse.self, from: imageData)
                                let recipe = Recipe(
                                    id: UUID(),
                                    title: partialRecipe.title,
                                    description: partialRecipe.description,
                                    ingredients: partialRecipe.ingredients,
                                    instructions: partialRecipe.instructions,
                                    imageBase64: imageResponse.data.first?.b64Json ?? "",
                                    createdAt: Date()
                                )
                                completion(.success(recipe))
                            } catch {
                                print("Image Decoding Error: \(error)")
                                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse image response. Please try again."])
                                completion(.failure(error))
                            }
                        case .failure(let error):
                            print("Image API Error: \(error)")
                            let updatedError = NSError(domain: "", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: "Failed to generate recipe image: \(error.localizedDescription). Please try again."])
                            completion(.failure(updatedError))
                        }
                    }
                } catch {
                    if let errorResponse = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        let errorMessage = errorResponse.error.message.isEmpty ? "Failed to generate recipe. Please try again." : errorResponse.error.message
                        let error = NSError(domain: "", code: errorResponse.error.code ?? -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        print("Text API Error: \(error) - \(errorMessage)")
                        completion(.failure(error))
                    } else {
                        print("Text Decoding Error: \(error)")
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse recipe response. Please try again."])
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                print("Recipe Text API Error: \(error)")
                let updatedError = NSError(domain: "", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: "Failed to generate recipe: \(error.localizedDescription). Please try again."])
                completion(.failure(updatedError))
            }
        }
    }

    private func makeAPIRequest(url: String, payload: [String: Any], retryCount: Int, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let urlObj = URL(string: url) else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL. Please try again."])
            print("Invalid URL: \(error)")
            completion(.failure(error))
            return
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request Payload: \(jsonString)")
            }
        } catch {
            print("Payload Error: \(error)")
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode API request. Please try again."])
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network Error: \(error)")
                let updatedError = NSError(domain: "", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: "Network error: \(error.localizedDescription). Please try again."])
                completion(.failure(updatedError))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API response. Please try again."])
                print("Invalid Response: \(error)")
                completion(.failure(error))
                return
            }

            print("HTTP Status: \(httpResponse.statusCode)")
            if let headers = httpResponse.allHeaderFields as? [String: String] {
                print("Headers: \(headers)")
            }

            if httpResponse.statusCode == 401 {
                let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Please try again."])
                print("Authentication Error: \(error)")
                completion(.failure(error))
                return
            }

            if [502, 429, 400].contains(httpResponse.statusCode) && retryCount < 3 {
                let retryDelay = httpResponse.statusCode == 429 ? 5.0 : 2.0
                print("Received \(httpResponse.statusCode) error, retrying (\(retryCount + 1)/3) after \(retryDelay) seconds...")
                DispatchQueue.global().asyncAfter(deadline: .now() + retryDelay) {
                    self.makeAPIRequest(url: url, payload: payload, retryCount: retryCount + 1, completion: completion)
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error (\(httpResponse.statusCode)): Please try again."])
                if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                    print("Error Response: \(errorBody)")
                }
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from API. Please try again."])
                print("No Data: \(error)")
                completion(.failure(error))
                return
            }

            completion(.success(data))
        }.resume()
    }
}
private struct IngredientApiResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String
        }
    }
}
private struct RecipeTextResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String
        }
    }
}
private struct PartialRecipe: Decodable {
    let title: String
    let description: String
    let ingredients: String
    let instructions: [String]
    let culture: String?

    enum CodingKeys: String, CodingKey {
        case title, description, ingredients, instructions, culture
    }
}
private struct ImageResponse: Decodable {
    let data: [ImageData]

    struct ImageData: Decodable {
        let b64Json: String

        enum CodingKeys: String, CodingKey {
            case b64Json = "b64_json"
        }
    }
}
private struct ApiErrorResponse: Decodable {
    let error: ErrorDetails

    struct ErrorDetails: Decodable {
        let message: String
        let code: Int?
    }
}
