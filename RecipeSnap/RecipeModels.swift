import Foundation
struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let title: String
    let description: String
    let ingredients: String
    let instructions: [String]
    let imageBase64: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, ingredients, instructions, imageBase64, createdAt
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.ingredients == rhs.ingredients &&
               lhs.instructions == rhs.instructions &&
               lhs.imageBase64 == rhs.imageBase64 &&
               lhs.createdAt == rhs.createdAt
    }
}
struct IngredientResponse: Decodable {
    let ingredients: [String]

    enum CodingKeys: String, CodingKey {
        case choices, message, content, ingredients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let choices = try? container.decode([MessageContainer].self, forKey: .choices), let firstChoice = choices.first {
            if let content = firstChoice.message.content {
                self.ingredients = content.ingredients
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: IngredientResponse.CodingKeys.content,
                    in: container,
                    debugDescription: "Invalid content format in message"
                )
            }
        } else if let ingredients = try? container.decode([String].self, forKey: .ingredients) {
            self.ingredients = ingredients
        } else {
            throw DecodingError.keyNotFound(
                IngredientResponse.CodingKeys.ingredients,
                .init(codingPath: container.codingPath, debugDescription: "No ingredients key found")
            )
        }
    }
}
private struct MessageContainer: Decodable {
    let message: Message

    enum CodingKeys: String, CodingKey {
        case message
    }
}
private struct Message: Decodable {
    let content: Content?

    enum CodingKeys: String, CodingKey {
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let contentString = try? container.decode(String.self, forKey: .content),
           let contentData = contentString.data(using: .utf8),
           let parsedContent = try? JSONDecoder().decode(Content.self, from: contentData) {
            self.content = parsedContent
        } else if let content = try? container.decode(Content.self, forKey: .content) {
            self.content = content
        } else {
            self.content = nil
        }
    }
}
private struct Content: Decodable {
    let ingredients: [String]

    enum CodingKeys: String, CodingKey {
        case ingredients
    }
}
struct APIErrorResponse: Decodable {
    let error: ErrorDetails

    struct ErrorDetails: Decodable {
        let message: String
        let code: Int?
    }
}
