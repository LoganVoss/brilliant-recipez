import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import RecipeCore

final class RecipeCoreTests: XCTestCase {
    private var session: URLSession!
    private var configuration: GrokConfiguration {
        GrokConfiguration(apiKey: "unit-test-placeholder", textModel: "test-text", visionModel: "test-vision")
    }
    private var service: GrokService { GrokService(configuration: configuration, session: session) }
    private let jpeg = Data([0xFF, 0xD8, 0xFF, 0x00])

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        MockURLProtocol.handler = nil
    }

    override func tearDown() {
        session.invalidateAndCancel()
        session = nil
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testNormalizerCleansWhitespaceCaseAndDuplicates() {
        XCTAssertEqual(
            IngredientNormalizer.normalize([" TOMATOES ", "tomatoes", "baby\n  SPINACH", "", "  ", "Lemon."]),
            ["Tomatoes", "Baby spinach", "Lemon"]
        )
    }

    func testDemoRecipeIsOfflineAndRoundTrips() throws {
        let data = try JSONEncoder().encode(Recipe.demo)
        XCTAssertEqual(try JSONDecoder().decode(Recipe.self, from: data), Recipe.demo)
        XCTAssertTrue(Recipe.demo.isDemo)
        XCTAssertFalse(Recipe.demo.ingredients.isEmpty)
        XCTAssertFalse(Recipe.demo.steps.isEmpty)
        XCTAssertEqual(Recipe.demo.ingredients.count, Set(Recipe.demo.ingredients.map(\.id)).count)
    }

    func testVisionRequestIncludesImageAndUsesVisionModel() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.x.ai/v1/chat/completions")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer unit-test-placeholder")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            let body = try Self.body(of: request)
            let raw = try XCTUnwrap(String(data: body, encoding: .utf8))
            XCTAssertTrue(raw.contains("data:image/jpeg;base64,/9j/AA=="))
            XCTAssertFalse(raw.contains("\\/"))
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(object["model"] as? String, "test-vision")
            XCTAssertEqual(object["max_completion_tokens"] as? Int, 500)
            XCTAssertNil(object["max_tokens"])
            XCTAssertEqual((object["response_format"] as? [String: String])?["type"], "json_object")
            let messages = try XCTUnwrap(object["messages"] as? [[String: Any]])
            let parts = try XCTUnwrap(messages.last?["content"] as? [[String: Any]])
            XCTAssertEqual(parts.count, 2)
            XCTAssertEqual((parts[1]["image_url"] as? [String: String])?["url"], "data:image/jpeg;base64,/9j/AA==")
            return Self.response(request, content: #"{"ingredients":["tomatoes","Tomatoes"," SPINACH "]}"#)
        }
        let names = try await service.identifyIngredients(jpegData: jpeg)
        XCTAssertEqual(names, ["Tomatoes", "Spinach"])
    }

    func testVisionAllowsNoRecognizableFood() async throws {
        MockURLProtocol.handler = { Self.response($0, content: #"{"ingredients":[]}"#) }
        let names = try await service.identifyIngredients(jpegData: jpeg)
        XCTAssertTrue(names.isEmpty)
    }

    func testRecipeRequestKeepsUserDataInJSONAndDisablesStaples() async throws {
        MockURLProtocol.handler = { request in
            let body = try Self.body(of: request)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(object["model"] as? String, "test-text")
            let messages = try XCTUnwrap(object["messages"] as? [[String: Any]])
            XCTAssertEqual(messages.count, 2)
            let input = try XCTUnwrap(messages[1]["content"] as? String)
            let inputObject = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(input.utf8)) as? [String: Any])
            XCTAssertEqual(inputObject["allowedIngredients"] as? [String], ["Tomatoes", "Chickpeas"])
            XCTAssertEqual(inputObject["direction"] as? String, "Quick \"bowl\"\nwith no fuss")
            return Self.response(request, content: Self.recipeJSON())
        }
        let recipe = try await service.generateRecipe(
            ingredients: ["tomatoes", "chickpeas"],
            preferences: RecipePreferences(direction: "Quick \"bowl\"\nwith no fuss", includeStaples: false)
        )
        XCTAssertEqual(recipe.title, "Tomato chickpea bowl")
        XCTAssertEqual(recipe.ingredients.map(\.name), ["Tomatoes", "Chickpeas"])
        XCTAssertFalse(recipe.isDemo)
    }

    func testJSONFenceIsAccepted() async throws {
        MockURLProtocol.handler = { Self.response($0, content: "```json\n\(Self.recipeJSON())\n```") }
        let result = try await service.generateRecipe(ingredients: ["Tomatoes", "Chickpeas"], preferences: .init())
        XCTAssertEqual(result.servings, 2)
    }

    func testMissingKeyDoesNotSendRequest() async {
        MockURLProtocol.handler = { request in
            XCTFail("A missing key must never send a network request")
            return Self.response(request, content: "{}")
        }
        let client = GrokService(configuration: .init(apiKey: "  ", textModel: "text", visionModel: "vision"), session: session)
        await assertError(.missingAPIKey) { try await client.identifyIngredients(jpegData: self.jpeg) }
    }

    func testInvalidConfigurationDoesNotSendRequest() async {
        let client = GrokService(configuration: .init(apiKey: "unit-test-placeholder", textModel: " ", visionModel: "vision"), session: session)
        await assertError(.invalidConfiguration) {
            try await client.generateRecipe(ingredients: ["Tomatoes"], preferences: .init())
        }
    }

    func testInvalidPhotoDoesNotSendRequest() async {
        await assertError(.invalidImage) { try await self.service.identifyIngredients(jpegData: Data("not a jpeg".utf8)) }
        await assertError(.invalidImage) { try await self.service.identifyIngredients(jpegData: Data()) }
    }

    func testInputBoundsFailBeforeNetwork() async {
        await assertError(.invalidIngredients) { try await self.service.generateRecipe(ingredients: [], preferences: .init()) }
        await assertError(.invalidIngredients) {
            try await self.service.generateRecipe(ingredients: [String(repeating: "x", count: 81)], preferences: .init())
        }
        await assertError(.invalidPreferences) {
            try await self.service.generateRecipe(ingredients: ["Tomatoes"], preferences: .init(servings: 0))
        }
        await assertError(.invalidPreferences) {
            try await self.service.generateRecipe(ingredients: ["Tomatoes"], preferences: .init(maximumMinutes: 181))
        }
    }

    func testHTTPStatusesAreClassifiedWithoutLeakingServerBodyOrRetrying() async {
        let cases: [(Int, GrokServiceError)] = [
            (400, .requestRejected), (401, .unauthorized), (403, .forbidden),
            (404, .modelUnavailable), (410, .modelUnavailable), (429, .rateLimited),
            (500, .serverUnavailable), (503, .serverUnavailable)
        ]
        for (status, expected) in cases {
            let counter = LockedCounter()
            MockURLProtocol.handler = { request in
                counter.increment()
                return (
                    HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!,
                    Data("private upstream details unit-test-placeholder".utf8)
                )
            }
            await assertError(expected) { try await self.service.identifyIngredients(jpegData: self.jpeg) }
            XCTAssertEqual(counter.value, 1, "A chargeable POST must not retry automatically")
            XCTAssertFalse(expected.localizedDescription.contains("private upstream"))
            XCTAssertFalse(expected.localizedDescription.contains("unit-test-placeholder"))
        }
    }

    func testNetworkFailureUsesSafeMessage() async {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        await assertError(.networkFailure) { try await self.service.identifyIngredients(jpegData: self.jpeg) }
    }

    func testCancellationIsNotReportedAsNetworkFailure() async {
        MockURLProtocol.handler = { _ in throw URLError(.cancelled) }
        do {
            _ = try await service.identifyIngredients(jpegData: jpeg)
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    func testCancelledTaskDoesNotProduceRecipe() async {
        MockURLProtocol.handler = { Self.response($0, content: Self.recipeJSON()) }
        let client = service
        let task = Task {
            try await client.generateRecipe(ingredients: ["Tomatoes", "Chickpeas"], preferences: .init())
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Cancelled work should not return a recipe")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    func testMalformedEnvelopeAndContentAreRejected() async {
        let bodies = [
            Data("not json".utf8),
            Data(#"{"choices":[]}"#.utf8),
            Data(#"{"choices":[{"message":{"content":null}}]}"#.utf8)
        ]
        for body in bodies {
            MockURLProtocol.handler = { request in
                (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, body)
            }
            await assertError(.invalidResponse) { try await self.service.identifyIngredients(jpegData: self.jpeg) }
        }
        for content in ["[]", "Here is your JSON: {}", #"{"ingredients":"Tomatoes"}"#, "```json\n{}"] {
            MockURLProtocol.handler = { Self.response($0, content: content) }
            await assertError(.invalidResponse) { try await self.service.identifyIngredients(jpegData: self.jpeg) }
        }
    }

    func testTruncatedCompletionIsRejectedEvenIfItsJSONParses() async {
        MockURLProtocol.handler = { Self.response($0, content: #"{"ingredients":["Tomatoes"]}"#, finishReason: "length") }
        await assertError(.invalidResponse) { try await self.service.identifyIngredients(jpegData: self.jpeg) }
    }

    func testUnknownIngredientIsRejected() async {
        MockURLProtocol.handler = { Self.response($0, content: Self.recipeJSON(secondIngredient: "Chicken")) }
        await assertError(.unexpectedIngredients) {
            try await self.service.generateRecipe(ingredients: ["Tomatoes", "Chickpeas"], preferences: .init())
        }
    }

    func testStaplesAreAllowedOnlyWhenEnabled() async throws {
        MockURLProtocol.handler = { Self.response($0, content: Self.recipeJSON(secondIngredient: "Olive oil")) }
        let recipe = try await service.generateRecipe(ingredients: ["Tomatoes", "Chickpeas"], preferences: .init())
        XCTAssertEqual(recipe.ingredients.last?.name, "Olive oil")
        await assertError(.unexpectedIngredients) {
            try await self.service.generateRecipe(ingredients: ["Tomatoes", "Chickpeas"], preferences: .init(includeStaples: false))
        }
    }

    func testEmptyStepDuplicateNamesAndPreferenceMismatchAreRejected() async {
        let variants = [
            Self.recipeJSON(step: "  "),
            Self.recipeJSON(secondIngredient: "tomatoes"),
            Self.recipeJSON(minutes: 31),
            Self.recipeJSON(servings: 4)
        ]
        for content in variants {
            MockURLProtocol.handler = { Self.response($0, content: content) }
            await assertError(.invalidResponse) {
                try await self.service.generateRecipe(ingredients: ["Tomatoes", "Chickpeas"], preferences: .init())
            }
        }
    }

    private func assertError<T>(
        _ expected: GrokServiceError,
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () async throws -> T
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? GrokServiceError, expected, file: file, line: line)
        }
    }

    private static func recipeJSON(
        secondIngredient: String = "Chickpeas",
        step: String = "Warm the tomatoes with the chickpeas until heated through.",
        minutes: Int = 20,
        servings: Int = 2
    ) -> String {
        let object: [String: Any] = [
            "title": "Tomato chickpea bowl", "summary": "A quick pantry bowl.", "cuisine": "Mediterranean inspired",
            "minutes": minutes, "servings": servings,
            "ingredients": [["name": "Tomatoes", "amount": "2"], ["name": secondIngredient, "amount": "1 cup"]],
            "steps": [step]
        ]
        return String(data: try! JSONSerialization.data(withJSONObject: object), encoding: .utf8)!
    }

    private static func response(_ request: URLRequest, content: String, finishReason: String = "stop") -> (HTTPURLResponse, Data) {
        let data = try! JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": content], "finish_reason": finishReason]]])
        return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
    }

    private static func body(of request: URLRequest) throws -> Data {
        if let body = request.httpBody { return body }
        let stream = try XCTUnwrap(request.httpBodyStream)
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    func increment() { lock.lock(); count += 1; lock.unlock() }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var storedHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get { lock.lock(); defer { lock.unlock() }; return storedHandler }
        set { lock.lock(); storedHandler = newValue; lock.unlock() }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
