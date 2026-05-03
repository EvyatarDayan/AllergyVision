//
//  OpenFoodFactsService.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import Foundation

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product/"
    
    private init() {}
    
    func fetchProduct(barcode: String, completion: @escaping (Result<Product, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(barcode).json") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                
                if result.status == 1, let productData = result.product {
                    let product = self.parseProduct(from: productData, barcode: barcode)
                    completion(.success(product))
                } else {
                    completion(.failure(APIError.productNotFound))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseProduct(from data: ProductData, barcode: String) -> Product {
        // Extract and clean all data to English only
        let allergens = extractAllergens(from: data)
        let ingredients = cleanToEnglish(data.ingredients_text)
        let traces = cleanTracesToEnglish(data.traces, tags: data.traces_tags)
        let categories = cleanCategoriesToEnglish(data.categories)
        let labels = cleanToEnglish(data.labels)
        
        return Product(
            id: barcode,
            barcode: barcode,
            name: data.product_name ?? "Unknown Product",
            brands: data.brands,
            imageUrl: data.image_url,
            ingredients: ingredients,
            allergens: allergens,
            allergensText: nil,
            traces: traces,
            labels: labels,
            categories: categories,
            nutritionGrade: cleanNutritionGrade(data.nutrition_grades)
        )
    }
    
    private func extractAllergens(from data: ProductData) -> [String] {
        var allergensList: [String] = []
        
        // From allergens_tags (preferred source)
        if let tags = data.allergens_tags {
            let tagAllergens = tags
                .filter { $0.hasPrefix("en:") } // Only English
                .map { $0.replacingOccurrences(of: "en:", with: "") }
                .map { $0.replacingOccurrences(of: "-", with: " ") }
                .map { $0.capitalized }
                .filter { !$0.isEmpty }
            allergensList.append(contentsOf: tagAllergens)
        }
        
        // Fallback to allergens field if no tags
        if allergensList.isEmpty, let allergensString = data.allergens {
            let allergens = allergensString
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0.hasPrefix("en:") || !$0.contains(":") } // Only English or no language prefix
                .map { $0.replacingOccurrences(of: "en:", with: "") }
                .map { $0.replacingOccurrences(of: "-", with: " ") }
                .map { $0.capitalized }
                .filter { !$0.isEmpty }
            allergensList.append(contentsOf: allergens)
        }
        
        // Detect allergens from categories (important for dairy, eggs, etc.)
        if let categoriesTags = data.categories_tags {
            let categoryAllergens = detectAllergensFromCategories(categoriesTags)
            allergensList.append(contentsOf: categoryAllergens)
        }
        
        // Detect allergens from ingredients text
        if let ingredientsText = data.ingredients_text?.lowercased() {
            let ingredientAllergens = detectAllergensFromIngredients(ingredientsText)
            allergensList.append(contentsOf: ingredientAllergens)
        }
        
        // Remove duplicates and return
        return Array(Set(allergensList)).sorted()
    }
    
    private func detectAllergensFromCategories(_ categories: [String]) -> [String] {
        var allergens: [String] = []
        
        let categoryMapping: [String: String] = [
            "dairies": "Milk",
            "cheeses": "Milk",
            "cream-cheeses": "Milk",
            "cheese-spreads": "Milk",
            "fermented-milk-products": "Milk",
            "yogurts": "Milk",
            "milk": "Milk",
            "eggs": "Eggs",
            "egg": "Eggs",
            "fish": "Fish",
            "fishes": "Fish",
            "seafood": "Fish",
            "shellfish": "Shellfish",
            "crustaceans": "Crustaceans",
            "molluscs": "Molluscs"
        ]
        
        for category in categories {
            let cleanCategory = category.replacingOccurrences(of: "en:", with: "")
            if let allergen = categoryMapping[cleanCategory] {
                allergens.append(allergen)
            }
        }
        
        return allergens
    }
    
    private func detectAllergensFromIngredients(_ ingredientsText: String) -> [String] {
        var allergens: [String] = []
        
        let allergenKeywords: [String: [String]] = [
            "Milk": ["milk", "cream", "butter", "cheese", "whey", "casein", "lactose", "yogurt", "yoghurt"],
            "Eggs": ["egg", "eggs", "albumin", "mayonnaise"],
            "Fish": ["fish", "anchovy", "cod", "salmon", "tuna", "sardine"],
            "Peanuts": ["peanut", "groundnut", "arachis"],
            "Soybeans": ["soy", "soya", "tofu", "edamame", "tempeh"],
            "Nuts": ["almond", "walnut", "cashew", "pecan", "hazelnut", "pistachio", "macadamia"],
            "Wheat": ["wheat", "flour", "gluten"],
            "Sesame": ["sesame", "tahini"],
            "Shellfish": ["shrimp", "prawn", "crab", "lobster", "crayfish"],
            "Mustard": ["mustard"],
            "Celery": ["celery"],
            "Lupin": ["lupin", "lupine"]
        ]
        
        for (allergen, keywords) in allergenKeywords {
            for keyword in keywords {
                if ingredientsText.contains(keyword) {
                    allergens.append(allergen)
                    break // Don't add the same allergen multiple times
                }
            }
        }
        
        return allergens
    }
    
    private func cleanToEnglish(_ text: String?) -> String? {
        guard let text = text, !text.isEmpty else { return nil }
        
        // If text contains language codes, extract only English
        if text.contains("en:") {
            let components = text.components(separatedBy: ",")
            let englishComponents = components
                .filter { $0.contains("en:") }
                .map { $0.replacingOccurrences(of: "en:", with: "") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { $0.replacingOccurrences(of: "-", with: " ") }
                .filter { !$0.isEmpty }
            
            return englishComponents.isEmpty ? text : englishComponents.joined(separator: ", ")
        }
        
        // Clean up formatting issues
        return cleanIngredientFormatting(text)
    }
    
    private func cleanIngredientFormatting(_ text: String) -> String {
        var cleaned = text
        
        // Remove all special characters and formatting
        cleaned = cleaned.replacingOccurrences(of: "_", with: "")
        cleaned = cleaned.replacingOccurrences(of: "*", with: "")
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")
        cleaned = cleaned.replacingOccurrences(of: "'", with: "")
        cleaned = cleaned.replacingOccurrences(of: "&", with: "and")
        
        // Remove HTML/XML entities
        cleaned = cleaned.replacingOccurrences(of: "&Quot;", with: "")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "")
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "and")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: "")
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        
        // Remove parentheses and their contents (like percentages and origins)
        cleaned = cleaned.replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
        
        // Remove percentage indicators and technical data
        cleaned = cleaned.replacingOccurrences(of: #"percent_[^,\s]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\d+%[^,\s]*"#, with: "", options: .regularExpression)
        
        // Remove origin information
        cleaned = cleaned.replacingOccurrences(of: #"Ursprung:[^,]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"Origin:[^,]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"EU[^,\s]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"Icke-EU[^,\s]*"#, with: "", options: .regularExpression)
        
        // Remove technical indicators
        cleaned = cleaned.replacingOccurrences(of: #"->[^,\s]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"fr:[^,\s]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"en:[^,\s]*"#, with: "", options: .regularExpression)
        
        // Remove numbers and technical codes
        cleaned = cleaned.replacingOccurrences(of: #"\d+\.\d+[^,\s]*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"E\d+[^,\s]*"#, with: "", options: .regularExpression)
        
        // Clean up multiple spaces and commas
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #",\s*,"#, with: ",", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #",\s*$"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"^\s*,"#, with: "", options: .regularExpression)
        
        // Remove leading/trailing commas and spaces
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
        
        // Translate common ingredient terms
        cleaned = translateCommonIngredients(cleaned)
        
        // Final cleanup - remove any remaining special characters
        cleaned = cleaned.replacingOccurrences(of: #"[^\w\s,]"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return cleaned
    }
    
    private func translateCommonIngredients(_ text: String) -> String {
        let translations: [String: String] = [
            // Swedish
            "rapsolja": "rapeseed oil",
            "vatten": "water",
            "chili": "chili",
            "socker": "sugar",
            "äggula": "egg yolk",
            "salt": "salt",
            "vitlök": "garlic",
            "ättiksprit": "vinegar spirit",
            "spiskummin": "cumin",
            "senapsfrö": "mustard seed",
            "vinäger": "vinegar",
            "jästextrakt": "yeast extract",
            "paprikapulver": "paprika powder",
            "arom": "flavoring",
            "konserveringsmedel": "preservatives",
            "förtjockningsmedel": "thickening agent",
            "surhetsreglerande medel": "acidity regulator",
            
            // Finnish
            "maito": "milk",
            "kerma": "cream",
            "suola": "salt",
            "happo": "acid",
            "sitruunahappo": "citric acid",
            "hapate": "starter culture",
            "stabilointiaineet": "stabilizers",
            "johanneksenleipäpuujauhe": "carob bean gum",
            "karrageeni": "carrageenan",
            "heratuote": "whey product",
            
            // French
            "lait": "milk",
            "crème": "cream",
            "sel": "salt",
            "acide": "acid",
            "acide citrique": "citric acid",
            "ferments": "starter culture",
            "stabilisants": "stabilizers",
            "farine de caroube": "carob bean gum",
            "carraghénane": "carrageenan",
            "lactosérum": "whey",
            
            // German
            "milch": "milk",
            "sahne": "cream",
            "salz": "salt",
            "säure": "acid",
            "zitronensäure": "citric acid",
            "ferment": "starter culture",
            "stabilisatoren": "stabilizers",
            "johannisbrotkernmehl": "carob bean gum",
            "carrageen": "carrageenan",
            "molke": "whey",
            
            // Spanish
            "leche": "milk",
            "crema": "cream",
            "sal": "salt",
            "ácido": "acid",
            "ácido cítrico": "citric acid",
            "fermentos": "starter culture",
            "estabilizantes": "stabilizers",
            "harina de algarroba": "carob bean gum",
            "carragenano": "carrageenan",
            "suero": "whey"
        ]
        
        var result = text.lowercased()
        
        for (foreign, english) in translations {
            result = result.replacingOccurrences(of: foreign, with: english)
        }
        
        // Capitalize first letter of each word
        return result.capitalized
    }
    
    private func cleanTracesToEnglish(_ traces: String?, tags: [String]?) -> String? {
        // Prefer tags as they're more structured
        if let tags = tags, !tags.isEmpty {
            let englishTraces = tags
                .filter { $0.hasPrefix("en:") }
                .map { $0.replacingOccurrences(of: "en:", with: "") }
                .map { $0.replacingOccurrences(of: "-", with: " ") }
                .map { $0.capitalized }
                .filter { !$0.isEmpty }
            
            return englishTraces.isEmpty ? nil : englishTraces.joined(separator: ", ")
        }
        
        // Fallback to traces field
        return cleanToEnglish(traces)
    }
    
    private func cleanCategoriesToEnglish(_ categories: String?) -> String? {
        guard let categories = categories, !categories.isEmpty else { return nil }
        
        // Categories are comma-separated with language prefixes
        let categoryList = categories
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("en:") || !$0.contains(":") } // Only English or no prefix
            .map { $0.replacingOccurrences(of: "en:", with: "") }
            .map { $0.replacingOccurrences(of: "-", with: " ") }
            .map { $0.capitalized }
            .filter { !$0.isEmpty }
        
        return categoryList.isEmpty ? nil : categoryList.joined(separator: ", ")
    }
    
    private func cleanNutritionGrade(_ grade: String?) -> String? {
        guard let grade = grade, !grade.isEmpty else { return nil }
        
        // Check if it's a valid grade (A, B, C, D, E)
        let validGrades = ["A", "B", "C", "D", "E"]
        let cleanGrade = grade.uppercased().trimmingCharacters(in: .whitespaces)
        
        // Only return if it's a valid grade
        return validGrades.contains(cleanGrade) ? cleanGrade : nil
    }
}

// MARK: - API Models
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: ProductData?
}

struct ProductData: Codable {
    let product_name: String?
    let brands: String?
    let image_url: String?
    let ingredients_text: String?
    let allergens: String?
    let allergens_tags: [String]?
    let traces: String?
    let traces_tags: [String]?
    let labels: String?
    let categories: String?
    let categories_tags: [String]?
    let ingredients: [[String: AnyCodable]]?
    let nutrition_grades: String?
}

// Helper for decoding dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Product Model
struct Product: Identifiable, Codable {
    let id: String
    let barcode: String
    let name: String
    let brands: String?
    let imageUrl: String?
    let ingredients: String?
    let allergens: [String]
    let allergensText: String?
    let traces: String?
    let labels: String?
    let categories: String?
    let nutritionGrade: String?
    
    var hasAllergens: Bool {
        !allergens.isEmpty
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .productNotFound:
            return "Product not found in database"
        }
    }
}

