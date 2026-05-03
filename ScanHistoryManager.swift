//
//  ScanHistoryManager.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import Foundation

class ScanHistoryManager: ObservableObject {
    static let shared = ScanHistoryManager()
    
    @Published var scanHistory: [Product] = []
    
    private let historyKey = "scan_history"
    private let maxHistoryItems = 100
    
    private init() {
        loadHistory()
    }
    
    func saveProduct(_ product: Product) {
        // Remove duplicate if exists (by barcode)
        scanHistory.removeAll { $0.barcode == product.barcode }
        
        // Add to beginning of array (most recent first)
        scanHistory.insert(product, at: 0)
        
        // Limit history size
        if scanHistory.count > maxHistoryItems {
            scanHistory = Array(scanHistory.prefix(maxHistoryItems))
        }
        
        // Persist to UserDefaults
        saveHistory()
    }
    
    func removeProduct(_ product: Product) {
        scanHistory.removeAll { $0.id == product.id }
        saveHistory()
    }
    
    func clearHistory() {
        scanHistory.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(scanHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            scanHistory = decoded
        } else {
            // Add test data if no history exists
            addTestData()
        }
    }
    
    private func addTestData() {
        let testProduct = Product(
            id: "1234567890123",
            barcode: "1234567890123",
            name: "Test Chocolate Bar",
            brands: "TestBrand",
            imageUrl: "https://images.openfoodfacts.org/images/products/123/456/789/0123/front_en.4.400.jpg",
            ingredients: "Sugar, Cocoa Butter, Cocoa Mass, Milk Powder, Emulsifier (Soy Lecithin), Vanilla Extract",
            allergens: ["Milk", "Soy"],
            allergensText: "Contains: Milk, Soy",
            traces: "May contain: Nuts, Gluten",
            labels: "Organic, Fair Trade",
            categories: "Snacks, Sweet snacks, Confectionery, Chocolate, Dark chocolate",
            nutritionGrade: "D"
        )
        
        scanHistory = [testProduct]
        saveHistory()
    }
}


