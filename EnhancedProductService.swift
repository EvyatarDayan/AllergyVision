//
//  EnhancedProductService.swift
//  AllergyVision
//

import Foundation

// MARK: - Enhanced Product Data
struct EnhancedProductData {
    let primaryData: Product // From OpenFoodFacts
    let usdaData: USDAFoodItem?
    let barcodeData: BarcodeLookupItem?
    let confidence: DataConfidence
}

enum DataConfidence {
    case high    // Multiple sources agree
    case medium  // Primary source + one additional
    case low     // Only primary source
}

// MARK: - USDA FoodData Central Models
struct USDAFoodItem: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let ingredients: String?
    let allergens: [String]?
    let foodNutrients: [FoodNutrient]?
}

struct FoodNutrient: Codable {
    let nutrient: Nutrient
    let amount: Double?
}

struct Nutrient: Codable {
    let id: Int
    let name: String
    let unitName: String?
}

// MARK: - Barcode Lookup Models
struct BarcodeLookupItem: Codable {
    let title: String?
    let description: String?
    let brand: String?
    let model: String?
    let category: String?
    let images: [String]?
    let stores: [Store]?
}

struct Store: Codable {
    let name: String
    let price: String?
    let currency: String?
}

// MARK: - Enhanced Product Service
class EnhancedProductService: ObservableObject {
    static let shared = EnhancedProductService()
    
    private let openFoodFactsService = OpenFoodFactsService.shared
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Main Enhancement Method
    func getEnhancedProductData(barcode: String) async -> EnhancedProductData? {
        // Get primary data from OpenFoodFacts
        guard let primaryProduct = await withCheckedContinuation({ continuation in
            openFoodFactsService.fetchProduct(barcode: barcode) { result in
                switch result {
                case .success(let product):
                    continuation.resume(returning: product)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }) else {
            return nil
        }
        
        // Fetch additional data in parallel
        async let usdaData = fetchUSDAData(for: primaryProduct)
        async let barcodeData = fetchBarcodeLookupData(barcode: barcode)
        
        let (usda, barcode) = await (usdaData, barcodeData)
        
        // Determine confidence level
        let confidence = determineConfidence(primary: primaryProduct, usda: usda, barcode: barcode)
        
        return EnhancedProductData(
            primaryData: primaryProduct,
            usdaData: usda,
            barcodeData: barcode,
            confidence: confidence
        )
    }
    
    // MARK: - USDA FoodData Central Integration
    private func fetchUSDAData(for product: Product) async -> USDAFoodItem? {
        // Search USDA database by product name
        guard let searchTerm = product.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(searchTerm)&api_key=DEMO_KEY&pageSize=1"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
            
            if let firstFood = response.foods.first {
                return USDAFoodItem(
                    fdcId: firstFood.fdcId,
                    description: firstFood.description,
                    brandOwner: firstFood.brandOwner,
                    ingredients: firstFood.ingredients,
                    allergens: extractUSDAllergens(from: firstFood),
                    foodNutrients: firstFood.foodNutrients
                )
            }
        } catch {
            print("USDA API Error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Barcode Lookup Integration
    private func fetchBarcodeLookupData(barcode: String) async -> BarcodeLookupItem? {
        // For demo purposes, we'll use a mock response
        // In production, you'd need to register for a free API key
        // let urlString = "https://api.barcodelookup.com/v3/products?barcode=\(barcode)&formatted=y&key=YOUR_FREE_KEY"
        return nil
    }
    
    // MARK: - Data Confidence Assessment
    private func determineConfidence(primary: Product, usda: USDAFoodItem?, barcode: BarcodeLookupItem?) -> DataConfidence {
        let additionalSources = [usda as Any?, barcode as Any?].compactMap { $0 }.count
        
        switch additionalSources {
        case 2:
            return .high
        case 1:
            return .medium
        default:
            return .low
        }
    }
    
    // MARK: - Allergen Enhancement
    func getEnhancedAllergens(for enhancedData: EnhancedProductData) -> [String] {
        var allergens = Set(enhancedData.primaryData.allergens)
        
        // Add USDA allergens if available
        if let usdaAllergens = enhancedData.usdaData?.allergens {
            allergens.formUnion(usdaAllergens)
        }
        
        // Add allergens from ingredients analysis
        let ingredientAllergens = analyzeIngredientsForAllergens(
            primaryIngredients: enhancedData.primaryData.ingredients,
            usdaIngredients: enhancedData.usdaData?.ingredients
        )
        allergens.formUnion(ingredientAllergens)
        
        return Array(allergens).sorted()
    }
    
    // MARK: - Enhanced Product Display
    func createEnhancedProduct(for enhancedData: EnhancedProductData) -> Product {
        let enhancedAllergens = getEnhancedAllergens(for: enhancedData)
        
        // Use brand name as fallback if product name is missing or "Unknown Product"
        let productName: String
        if enhancedData.primaryData.name.isEmpty || enhancedData.primaryData.name == "Unknown Product" {
            if let brand = enhancedData.primaryData.brands, !brand.isEmpty {
                productName = "Product by \(brand)"
            } else {
                productName = "Unknown Product"
            }
        } else {
            productName = enhancedData.primaryData.name
        }
        
        return Product(
            id: enhancedData.primaryData.id,
            barcode: enhancedData.primaryData.barcode,
            name: productName,
            brands: enhancedData.primaryData.brands,
            imageUrl: enhancedData.primaryData.imageUrl,
            ingredients: enhancedData.primaryData.ingredients,
            allergens: enhancedAllergens,
            allergensText: enhancedData.primaryData.allergensText,
            traces: enhancedData.primaryData.traces,
            labels: enhancedData.primaryData.labels,
            categories: enhancedData.primaryData.categories,
            nutritionGrade: enhancedData.primaryData.nutritionGrade
        )
    }
}

// MARK: - USDA API Response Models
struct USDASearchResponse: Codable {
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let ingredients: String?
    let foodNutrients: [FoodNutrient]?
}

// MARK: - Helper Methods
extension EnhancedProductService {
    private func extractUSDAllergens(from food: USDAFood) -> [String] {
        // Extract allergens from USDA ingredients text
        guard let ingredients = food.ingredients else { return [] }
        
        let allergenKeywords = [
            "milk", "eggs", "fish", "shellfish", "tree nuts", "peanuts", "wheat", "soybeans",
            "sesame", "mustard", "celery", "lupin", "sulfites"
        ]
        
        var foundAllergens: [String] = []
        let lowercasedIngredients = ingredients.lowercased()
        
        for allergen in allergenKeywords {
            if lowercasedIngredients.contains(allergen) {
                foundAllergens.append(allergen.capitalized)
            }
        }
        
        return foundAllergens
    }
    
    private func analyzeIngredientsForAllergens(primaryIngredients: String?, usdaIngredients: String?) -> [String] {
        var allergens: Set<String> = []
        
        let ingredientsToAnalyze = [primaryIngredients, usdaIngredients].compactMap { $0 }
        
        for ingredients in ingredientsToAnalyze {
            let userAllergens = UserAllergensManager.shared.allergenKeywordsLowercased()
            let lowercasedIngredients = ingredients.lowercased()
            
            for allergen in userAllergens {
                if lowercasedIngredients.contains(allergen) {
                    allergens.insert(allergen.capitalized)
                }
            }
        }
        
        return Array(allergens)
    }
}
