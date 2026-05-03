//
//  ShoppingListManager.swift
//  AllergyVision
//

import Foundation

class ShoppingListManager: ObservableObject {
    static let shared = ShoppingListManager()
    
    @Published var shoppingList: [Product] = []
    @Published var completedItems: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let shoppingListKey = "shoppingList"
    private let completedItemsKey = "completedItems"
    
    private init() {
        loadShoppingList()
        loadCompletedItems()
    }
    
    func addToShoppingList(_ product: Product) {
        // Check if product is already in the list
        if !shoppingList.contains(where: { $0.id == product.id }) {
            shoppingList.append(product)
            saveShoppingList()
        }
    }
    
    func removeFromShoppingList(_ product: Product) {
        shoppingList.removeAll { $0.id == product.id }
        completedItems.remove(product.id)
        saveShoppingList()
        saveCompletedItems()
    }
    
    func isInShoppingList(_ product: Product) -> Bool {
        return shoppingList.contains { $0.id == product.id }
    }
    
    func toggleCompleted(_ product: Product) {
        if completedItems.contains(product.id) {
            completedItems.remove(product.id)
        } else {
            completedItems.insert(product.id)
        }
        saveCompletedItems()
    }
    
    func isCompleted(_ product: Product) -> Bool {
        return completedItems.contains(product.id)
    }
    
    func clearShoppingList() {
        shoppingList.removeAll()
        completedItems.removeAll()
        saveShoppingList()
        saveCompletedItems()
    }
    
    private func saveShoppingList() {
        if let encoded = try? JSONEncoder().encode(shoppingList) {
            userDefaults.set(encoded, forKey: shoppingListKey)
        }
    }
    
    private func loadShoppingList() {
        if let data = userDefaults.data(forKey: shoppingListKey),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            shoppingList = decoded
        }
    }
    
    private func saveCompletedItems() {
        let array = Array(completedItems)
        userDefaults.set(array, forKey: completedItemsKey)
    }
    
    private func loadCompletedItems() {
        if let array = userDefaults.array(forKey: completedItemsKey) as? [String] {
            completedItems = Set(array)
        }
    }
}
