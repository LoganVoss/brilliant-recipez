import XCTest
@testable import RecipeCore

final class FoodSuggestionFilterTests: XCTestCase {
    func testGenericAndNonfoodClassificationsDoNotBecomeIngredients() {
        XCTAssertEqual(FoodSuggestionFilter.suggestions(
            classifications: ["food", "vegetable", "fruit", "kitchen", "mushroom", "wild_plant", "light_bulb"], labels: []), [])
    }

    func testExactLabelsHandleTaxonomySeparatorsAndDeduplicate() {
        XCTAssertEqual(FoodSuggestionFilter.suggestions(
            classifications: ["bell_pepper", "tomato", "tomatoes"], labels: ["Organic tomatoes 400 g"]),
            ["Bell pepper", "Tomatoes"])
    }

    func testLabelsNeverMatchAnIngredientSubstring() {
        XCTAssertEqual(FoodSuggestionFilter.suggestions(classifications: [], labels: ["Pineapple", "Almond milk", "Coconut milk"]),
                       ["Pineapple", "Almond milk", "Coconut milk"])
        XCTAssertEqual(FoodSuggestionFilter.suggestions(classifications: [], labels: ["Applewood", "Eggplant shampoo", "Cornflower"]), [])
    }

    func testAllergenClaimsAndPreparedFoodLabelsAreNotIngredientEvidence() {
        XCTAssertEqual(FoodSuggestionFilter.suggestions(classifications: [], labels: [
            "Contains milk", "Milk free", "No milk", "Without eggs", "May contain eggs",
            "Ingredients: tomatoes", "Tomato soup", "Tomato sauce", "Lemon scented cleaner"
        ]), [])
    }

    func testShortProductLabelsAreAcceptedWithoutInferringUnknownProducts() {
        XCTAssertEqual(FoodSuggestionFilter.suggestions(classifications: [], labels: [
            "Canned chickpeas", "Frozen spinach", "Diced tomatoes", "Fresh baby carrots",
            "Tomatoes and unknown ingredients", "Chocolate milk", "A very long promotional label about fresh delicious tomatoes"
        ]), ["Chickpeas", "Spinach", "Tomatoes", "Carrots"])
    }
}
