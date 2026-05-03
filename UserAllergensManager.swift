//
//  UserAllergensManager.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import Foundation

class UserAllergensManager: ObservableObject {
    static let shared = UserAllergensManager()
    
    @Published var selectedAllergens: Set<String> = []
    
    private let userDefaultsKey = "UserSelectedAllergens"
    
    private init() {
        loadAllergens()
    }
    
    func saveAllergens(_ allergens: Set<String>) {
        selectedAllergens = allergens
        let array = Array(allergens)
        UserDefaults.standard.set(array, forKey: userDefaultsKey)
    }
    
    func loadAllergens() {
        if let array = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            selectedAllergens = Set(array)
        }
    }
    
    func clearAllergens() {
        selectedAllergens.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // Produce a normalized set of keyword tokens (lowercased) that should be
    // highlighted inside ingredient strings. This maps selections like
    // "Milk - Cow" to the base token "milk" and also includes specific tokens
    // where relevant (e.g., "Fish - Salmon" -> ["fish", "salmon"]).
    func allergenKeywordsLowercased() -> Set<String> {
        var keywords: Set<String> = []
        for selection in selectedAllergens {
            let lower = selection.lowercased()
            // Split on hyphen to capture category and specific item
            let parts = lower.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if let first = parts.first {
                // Normalize some categories
                var category = first
                if category == "tree nut" { category = "nut" }
                keywords.insert(category)
            }
            if parts.count == 2 {
                var specific = parts[1]
                // Map common specific phrases to a single token
                if specific.hasSuffix(" nut") {
                    specific = String(specific.dropLast(4)) // remove " nut"
                }
                keywords.insert(specific)
            }
        }
        return keywords
    }

    // Check if an ingredient contains any of the user's selected allergens
    func containsUserAllergens(_ ingredient: String) -> Bool {
        let ingredientLower = ingredient.lowercased()
        
        for allergen in selectedAllergens {
            let allergenLower = allergen.lowercased()
            
            // Direct match
            if ingredientLower.contains(allergenLower) {
                return true
            }
            
            // Check for common variations and synonyms
            if checkAllergenVariations(ingredient: ingredientLower, allergen: allergenLower) {
                return true
            }
        }
        
        return false
    }
    
    // Check for common allergen variations and synonyms
    private func checkAllergenVariations(ingredient: String, allergen: String) -> Bool {
        let variations: [String: [String]] = [
            "milk": ["dairy", "lactose", "whey", "casein", "cream", "butter", "cheese"],
            "egg": ["eggs", "albumin", "lecithin"],
            "wheat": ["flour", "gluten", "bread", "pasta"],
            "soy": ["soybean", "soya", "tofu", "miso"],
            "nuts": ["almond", "walnut", "hazelnut", "cashew", "pecan", "pistachio", "brazil", "macadamia"],
            "peanut": ["peanuts", "groundnut"],
            "fish": ["salmon", "tuna", "cod", "haddock", "anchovy"],
            "shellfish": ["shrimp", "crab", "lobster", "crayfish"],
            "sesame": ["tahini", "sesame seed"],
            "mustard": ["mustard seed"],
            "celery": ["celery seed"],
            "sulfites": ["sulphites", "sulfur dioxide"]
        ]
        
        if let synonyms = variations[allergen] {
            for synonym in synonyms {
                if ingredient.contains(synonym) {
                    return true
                }
            }
        }
        
        return false
    }
}
