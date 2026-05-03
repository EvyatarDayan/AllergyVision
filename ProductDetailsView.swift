//
//  ProductDetailsView.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI

struct ProductDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var shoppingListManager = ShoppingListManager.shared
    let product: Product
    let dataConfidence: DataConfidence = .medium // This would be passed from the scanner
    
    private var confidenceIcon: String {
        switch dataConfidence {
        case .high:
            return "checkmark.circle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "questionmark.circle.fill"
        }
    }
    
    private var confidenceColor: Color {
        switch dataConfidence {
        case .high:
            return .green
        case .medium:
            return .orange
        case .low:
            return .red
        }
    }
    
    private var confidenceText: String {
        switch dataConfidence {
        case .high:
            return "High (Multiple Sources)"
        case .medium:
            return "Medium (2 Sources)"
        case .low:
            return "Low (Single Source)"
        }
    }
    
    private var confidenceLevelNumber: String {
        switch dataConfidence {
        case .high:
            return "3"
        case .medium:
            return "2"
        case .low:
            return "1"
        }
    }
    
    private func confidenceLevelColor(_ level: String) -> Color {
        switch level {
        case "3":
            return .green
        case "2":
            return .orange
        case "1":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatBarcode(_ barcode: String) -> String {
        // Format barcode with spaces for better readability
        let cleaned = barcode.replacingOccurrences(of: " ", with: "")
        
        // Add spaces every 4 digits for better readability
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        
        return formatted
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                Image("GenericProduct")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            @unknown default:
                                Image("GenericProduct")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .background(Color.gray.opacity(0.1))
                    } else {
                        // No image URL provided
                        Image("GenericProduct")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color.gray.opacity(0.1))
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        // Product Name
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Brands
                        if let brands = product.brands, !brands.isEmpty {
                            HStack {
                                Text("Brand:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text(brands)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        // Barcode
                        HStack {
                            Image(systemName: "barcode")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 32)
                            Text(formatBarcode(product.barcode))
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Allergen Warning
                        if product.hasAllergens || (product.ingredients != nil && !product.ingredients!.isEmpty) {
                            let combinedAllergens = getAllergensFromProduct(product)
                            if !combinedAllergens.isEmpty {
                                AllergenWarningCard(allergens: combinedAllergens)
                            } else {
                                NoAllergenInfoCard()
                            }
                        } else {
                            NoAllergenInfoCard()
                        }
                        
                        // Traces
                        if let traces = product.traces, !traces.isEmpty {
                            TracesWarningCard(traces: traces)
                        }
                        
                        Divider()
                        
                        // Data Confidence
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Confidence", systemImage: "chart.bar.fill")
                                .font(.headline)
                            
                            HStack(spacing: 0) {
                                Text("DATA SOURCES")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    ForEach(["1", "2", "3"], id: \.self) { level in
                                        Text(level)
                                            .font(.system(size: level == confidenceLevelNumber ? 24 : 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: level == confidenceLevelNumber ? 36 : 28, height: level == confidenceLevelNumber ? 36 : 28)
                                            .background(confidenceLevelColor(level))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(level == confidenceLevelNumber ? Color.black : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Divider()
                        
                        // Nutrition Grade
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Nutrition", systemImage: "heart.fill")
                                .font(.headline)
                            
                            HStack(spacing: 0) {
                                Text("NUTRI-SCORE")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Spacer()
                                
                                if let grade = product.nutritionGrade, !grade.isEmpty {
                                    HStack(spacing: 4) {
                                        ForEach(["A", "B", "C", "D", "E"], id: \.self) { letter in
                                            Text(letter)
                                                .font(.system(size: letter == grade.uppercased() ? 24 : 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: letter == grade.uppercased() ? 36 : 28, height: letter == grade.uppercased() ? 36 : 28)
                                                .background(nutritionGradeColor(letter))
                                                .cornerRadius(6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(letter == grade.uppercased() ? Color.black : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                } else {
                                    Text("No information")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Divider()
                        
                        // Ingredients
                        if let ingredients = product.ingredients, !ingredients.isEmpty {
                            HighlightedIngredientsView(ingredients: ingredients)
                        } else {
                            // No ingredient information
                            VStack(alignment: .leading, spacing: 12) {
                                Text("INGREDIENTS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                    
                                    Text("No ingredient information")
                                        .font(.body)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                )
                            }
                        }
                        
                        // Disclaimer
                        Text("Allergen information may be incomplete or inaccurate; always verify the label before consuming.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if shoppingListManager.isInShoppingList(product) {
                            shoppingListManager.removeFromShoppingList(product)
                        } else {
                            shoppingListManager.addToShoppingList(product)
                        }
                    }) {
                        Image(systemName: shoppingListManager.isInShoppingList(product) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getAllergensFromProduct(_ product: Product) -> [String] {
        var allAllergens = Set<String>()
        
        // Add allergens from API data (normalized)
        for allergen in product.allergens {
            let normalizedAllergen = normalizeAllergenName(allergen)
            allAllergens.insert(normalizedAllergen)
        }
        
        // Add allergens detected from ingredients
        if let ingredients = product.ingredients, !ingredients.isEmpty {
            let highlightedView = HighlightedIngredientsView(ingredients: ingredients)
            let detectedAllergens = highlightedView.detectedAllergens()
            allAllergens.formUnion(detectedAllergens)
        }
        
        return Array(allAllergens).sorted()
    }
    
    // Function to normalize allergen names to avoid duplicates like "egg" and "eggs"
    private func normalizeAllergenName(_ allergen: String) -> String {
        let lowercased = allergen.lowercased()
        
        // Define normalization rules to avoid duplicates
        let normalizationMap: [String: String] = [
            // Eggs
            "egg": "Egg",
            "eggs": "Egg",
            "egg yolk": "Egg",
            "egg white": "Egg",
            "egg whites": "Egg",
            "egg yolks": "Egg",
            
            // Milk
            "milk": "Milk",
            "milks": "Milk",
            "cow milk": "Milk",
            "goat milk": "Milk",
            "sheep milk": "Milk",
            "skimmed milk": "Milk",
            "whole milk": "Milk",
            "milk powder": "Milk",
            "milk protein": "Milk",
            "milk fat": "Milk",
            
            // Fish
            "fish": "Fish",
            "salmon": "Fish",
            "tuna": "Fish",
            "cod": "Fish",
            "haddock": "Fish",
            "anchovy": "Fish",
            "sardine": "Fish",
            "mackerel": "Fish",
            
            // Shellfish
            "shellfish": "Shellfish",
            "shrimp": "Shellfish",
            "crab": "Shellfish",
            "lobster": "Shellfish",
            "crayfish": "Shellfish",
            "prawn": "Shellfish",
            "prawns": "Shellfish",
            
            // Tree nuts
            "nuts": "Tree Nuts",
            "tree nuts": "Tree Nuts",
            "almond": "Tree Nuts",
            "almonds": "Tree Nuts",
            "hazelnut": "Tree Nuts",
            "hazelnuts": "Tree Nuts",
            "walnut": "Tree Nuts",
            "walnuts": "Tree Nuts",
            "cashew": "Tree Nuts",
            "cashews": "Tree Nuts",
            "pecan": "Tree Nuts",
            "pecans": "Tree Nuts",
            "pistachio": "Tree Nuts",
            "pistachios": "Tree Nuts",
            "brazil nut": "Tree Nuts",
            "brazil nuts": "Tree Nuts",
            "macadamia": "Tree Nuts",
            "macadamias": "Tree Nuts",
            
            // Peanuts
            "peanut": "Peanut",
            "peanuts": "Peanut",
            "groundnut": "Peanut",
            "groundnuts": "Peanut",
            
            // Wheat
            "wheat": "Wheat",
            "gluten": "Wheat",
            "wheat flour": "Wheat",
            "wheat protein": "Wheat",
            "wheat starch": "Wheat",
            
            // Soy
            "soy": "Soy",
            "soybean": "Soy",
            "soybeans": "Soy",
            "soy protein": "Soy",
            "soy flour": "Soy",
            "soy milk": "Soy",
            "soy sauce": "Soy",
            "soy lecithin": "Soy",
            
            // Sesame
            "sesame": "Sesame",
            "sesame seed": "Sesame",
            "sesame seeds": "Sesame",
            "sesame oil": "Sesame",
            
            // Mustard
            "mustard": "Mustard",
            "mustard seed": "Mustard",
            "mustard seeds": "Mustard",
            "mustard powder": "Mustard",
            
            // Celery
            "celery": "Celery",
            "celery seed": "Celery",
            "celery seeds": "Celery",
            "celery salt": "Celery",
            
            // Lupin
            "lupin": "Lupin",
            "lupine": "Lupin",
            "lupins": "Lupin",
            
            // Sulfites
            "sulfites": "Sulfites",
            "sulphites": "Sulfites",
            "sulfur dioxide": "Sulfites",
            "sulphur dioxide": "Sulfites",
            
            // Mollusks
            "mollusk": "Mollusk",
            "mollusks": "Mollusk",
            "mollusc": "Mollusk",
            "molluscs": "Mollusk",
            "clam": "Mollusk",
            "clams": "Mollusk",
            "mussel": "Mollusk",
            "mussels": "Mollusk",
            "oyster": "Mollusk",
            "oysters": "Mollusk",
            "squid": "Mollusk",
            "scallop": "Mollusk",
            "scallops": "Mollusk",
            "octopus": "Mollusk",
            
            // Other common allergens
            "corn": "Corn",
            "maize": "Corn",
            "buckwheat": "Buckwheat",
            "chickpea": "Chickpea",
            "chickpeas": "Chickpea",
            "lentil": "Lentil",
            "lentils": "Lentil",
            "pea": "Pea",
            "peas": "Pea",
            "bean": "Bean",
            "beans": "Bean",
            "kidney bean": "Bean",
            "kidney beans": "Bean",
            "navy bean": "Bean",
            "navy beans": "Bean",
            "pinto bean": "Bean",
            "pinto beans": "Bean",
            "black bean": "Bean",
            "black beans": "Bean",
            "oats": "Oats",
            "oat": "Oats",
            "garlic": "Garlic",
            "onion": "Onion",
            "onions": "Onion",
            "kiwi": "Kiwi",
            "banana": "Banana",
            "bananas": "Banana",
            "avocado": "Avocado",
            "avocados": "Avocado",
            "mango": "Mango",
            "mangos": "Mango",
            "mangoes": "Mango",
            "apple": "Apple",
            "apples": "Apple",
            "peach": "Peach",
            "peaches": "Peach",
            "tomato": "Tomato",
            "tomatoes": "Tomato",
            "citrus": "Citrus",
            "orange": "Citrus",
            "oranges": "Citrus",
            "lemon": "Citrus",
            "lemons": "Citrus",
            "lime": "Citrus",
            "limes": "Citrus",
            "grapefruit": "Citrus",
            "grapefruits": "Citrus",
            "strawberry": "Strawberry",
            "strawberries": "Strawberry",
            "chocolate": "Chocolate",
            "cocoa": "Chocolate",
            "yeast": "Yeast",
            "poppy seed": "Poppy Seed",
            "poppy seeds": "Poppy Seed",
            "sunflower seed": "Sunflower Seed",
            "sunflower seeds": "Sunflower Seed",
            "pumpkin seed": "Pumpkin Seed",
            "pumpkin seeds": "Pumpkin Seed"
        ]
        
        // Return normalized name if found, otherwise capitalize the original
        return normalizationMap[lowercased] ?? allergen.capitalized
    }
    
    private func nutritionGradeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A": return Color(red: 0.2, green: 0.6, blue: 0.2) // Dark green
        case "B": return Color(red: 0.4, green: 0.7, blue: 0.3) // Light green
        case "C": return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
        case "D": return Color(red: 1.0, green: 0.5, blue: 0.0) // Orange
        case "E": return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
        default: return .gray
        }
    }
}

// MARK: - Allergen Warning Card
struct AllergenWarningCard: View {
    let allergens: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text("Allergen Warning")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
//            Text("Contains the following:")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(allergens, id: \.self) { allergen in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                        Text(allergen)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.leading, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Traces Warning Card
struct TracesWarningCard: View {
    let traces: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text("May Contain Traces Of")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            // Parse traces and display with red bullet points like allergen warning
            VStack(alignment: .leading, spacing: 8) {
                let traceItems = traces.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                ForEach(traceItems, id: \.self) { trace in
                    if !trace.isEmpty {
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                            Text(trace)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding(.leading, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - No Allergen Info Card
struct NoAllergenInfoCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No Allergen Information")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("Allergen information not available in database")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    ProductDetailsView(product: Product(
        id: "123",
        barcode: "3017620422003",
        name: "Nutella",
        brands: "Ferrero",
        imageUrl: nil,
        ingredients: "Sugar, Palm Oil, Hazelnuts, Cocoa, Milk, Lecithin, Vanillin",
        allergens: ["Milk", "Nuts", "Hazelnuts"],
        allergensText: "en:milk,en:nuts",
        traces: "en:gluten,en:eggs",
        labels: nil,
        categories: "Spreads",
        nutritionGrade: "e"
    ))
}

