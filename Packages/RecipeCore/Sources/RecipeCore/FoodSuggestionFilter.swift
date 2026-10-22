import Foundation

/// Filters Vision's broad image labels and OCR into a small, editable food vocabulary.
/// It cannot establish identity, edibility, allergens, or contents of a package.
public enum FoodSuggestionFilter {
    public static func suggestions(classifications: [String], labels: [String]) -> [String] {
        let classified = classifications.compactMap { aliases[words($0).joined(separator: " ")] }
        let labeled = labels.compactMap { label -> String? in
            let tokens = words(label)
            guard !tokens.isEmpty, tokens.count <= 6,
                  !tokens.contains(where: excludedLabelWords.contains) else { return nil }
            // Match a whole product label after removing only simple packaging descriptors.
            // "Pineapple" cannot match "Apple"; "almond milk" cannot become dairy milk.
            let product = tokens.filter { !productModifiers.contains($0) }.joined(separator: " ")
            return aliases[product]
        }
        return Array(IngredientNormalizer.normalize(classified + labeled).prefix(30))
    }

    private static func words(_ text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
    }

    private static let productModifiers: Set<String> = [
        "fresh", "organic", "canned", "frozen", "dried", "chopped", "diced", "whole", "sliced",
        "baby", "ripe", "large", "small", "medium", "oz", "lb", "lbs", "g", "kg", "ml", "litre", "liter"
    ]

    private static let excludedLabelWords: Set<String> = [
        "free", "without", "no", "contains", "contain", "may", "ingredients", "allergen", "allergens",
        "nutrition", "calories", "soap", "shampoo", "cleaner", "scent", "flavor", "flavour",
        "flavored", "flavoured", "soup", "sauce", "dressing", "candy"
    ]

    private static let aliases: [String: String] = [
        "apple": "Apples", "apples": "Apples", "banana": "Bananas", "bananas": "Bananas",
        "orange": "Oranges", "oranges": "Oranges", "lemon": "Lemon", "lemons": "Lemon",
        "lime": "Lime", "limes": "Lime", "avocado": "Avocado", "avocados": "Avocado",
        "tomato": "Tomatoes", "tomatoes": "Tomatoes", "cherry tomato": "Cherry tomatoes", "cherry tomatoes": "Cherry tomatoes",
        "potato": "Potatoes", "potatoes": "Potatoes", "sweet potato": "Sweet potatoes", "sweet potatoes": "Sweet potatoes",
        "onion": "Onion", "onions": "Onion", "red onion": "Red onion", "garlic": "Garlic",
        "carrot": "Carrots", "carrots": "Carrots", "broccoli": "Broccoli", "cauliflower": "Cauliflower",
        "spinach": "Spinach", "kale": "Kale", "lettuce": "Lettuce", "cabbage": "Cabbage",
        "cucumber": "Cucumber", "cucumbers": "Cucumber", "zucchini": "Zucchini", "courgette": "Zucchini",
        "eggplant": "Eggplant", "aubergine": "Eggplant", "asparagus": "Asparagus",
        "bell pepper": "Bell pepper", "bell peppers": "Bell pepper", "red pepper": "Red bell pepper",
        "green pepper": "Green bell pepper", "corn": "Corn", "sweetcorn": "Corn", "peas": "Peas",
        "green beans": "Green beans", "strawberry": "Strawberries", "strawberries": "Strawberries",
        "blueberry": "Blueberries", "blueberries": "Blueberries", "grape": "Grapes", "grapes": "Grapes",
        "pear": "Pears", "pears": "Pears", "peach": "Peaches", "peaches": "Peaches",
        "pineapple": "Pineapple", "mango": "Mango", "watermelon": "Watermelon",
        "rice": "Rice", "brown rice": "Brown rice", "pasta": "Pasta", "spaghetti": "Spaghetti",
        "oats": "Oats", "rolled oats": "Oats", "flour": "Flour", "bread": "Bread",
        "chickpea": "Chickpeas", "chickpeas": "Chickpeas", "garbanzo beans": "Chickpeas",
        "black beans": "Black beans", "kidney beans": "Kidney beans", "lentils": "Lentils",
        "tofu": "Tofu", "egg": "Eggs", "eggs": "Eggs", "milk": "Milk", "butter": "Butter",
        "cheese": "Cheese", "cheddar": "Cheddar", "yogurt": "Yogurt", "yoghurt": "Yogurt",
        "almond milk": "Almond milk", "oat milk": "Oat milk", "soy milk": "Soy milk", "coconut milk": "Coconut milk",
        "olive oil": "Olive oil", "salt": "Salt", "black pepper": "Black pepper",
        "basil": "Basil", "parsley": "Parsley", "cilantro": "Cilantro", "coriander": "Cilantro"
    ]
}
