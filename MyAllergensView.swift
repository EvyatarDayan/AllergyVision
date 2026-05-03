//
//  MyAllergensView.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI

struct MyAllergensView: View {
    @State private var selectedAllergens: Set<String> = []
    @State private var searchText = ""
    @State private var showClearConfirmation = false
    @StateObject private var userAllergensManager = UserAllergensManager.shared
    @Environment(\.dismiss) var dismiss
    
    private let allAllergens = [
        "Apple",
        "Avocado",
        "Banana",
        "Bean - Black",
        "Bean - Kidney",
        "Bean - Navy",
        "Bean - Pinto",
        "Buckwheat",
        "Celery",
        "Chickpea",
        "Chocolate",
        "Citrus - Grapefruit",
        "Citrus - Lemon",
        "Citrus - Lime",
        "Citrus - Orange",
        "Clam",
        "Corn",
        "Crab",
        "Crayfish",
        "Egg - Chicken",
        "Egg - Duck",
        "Fish - Anchovy",
        "Fish - Cod",
        "Fish - Haddock",
        "Fish - Salmon",
        "Fish - Tuna",
        "Garlic",
        "Kiwi",
        "Lentil",
        "Lobster",
        "Lupin",
        "Mango",
        "Milk - Cow",
        "Milk - Goat",
        "Milk - Sheep",
        "Mollusk - Clam",
        "Mollusk - Mussel",
        "Mollusk - Octopus",
        "Mollusk - Oyster",
        "Mollusk - Scallop",
        "Mollusk - Squid",
        "Mustard",
        "Oats",
        "Onion",
        "Pea",
        "Peach",
        "Peanut",
        "Pistachio",
        "Poppy Seed",
        "Pumpkin Seed",
        "Sesame",
        "Shellfish - Crab",
        "Shellfish - Crayfish",
        "Shellfish - Lobster",
        "Shellfish - Shrimp",
        "Soybean",
        "Strawberry",
        "Sunflower Seed",
        "Sulfites",
        "Tomato",
        "Nut - Almond",
        "Nut - Brazil",
        "Nut - Cashew",
        "Nut - Hazelnut",
        "Nut - Macadamia",
        "Nut - Pecan",
        "Nut - Pistachio",
        "Nut - Walnut",
        "Wheat",
        "Yeast"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("My Allergens")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search allergens...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .submitLabel(.done)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Allergens List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAllergens, id: \.self) { allergen in
                            AllergenRow(
                                allergen: allergen,
                                isSelected: selectedAllergens.contains(allergen)
                            ) {
                                toggleAllergen(allergen)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 16) {
                    HStack {
                        Text(selectedAllergens.isEmpty ? "No allergens selected" : "\(selectedAllergens.count) allergen\(selectedAllergens.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Clear all") {
                            showClearConfirmation = true
                        }
                        .font(.subheadline)
                        .foregroundColor(selectedAllergens.isEmpty ? .gray : .red)
                        .disabled(selectedAllergens.isEmpty)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .padding(.leading, 20)
                    
                    Button(action: {
                        userAllergensManager.saveAllergens(selectedAllergens)
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("My Allergens")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        }
        .onAppear {
            loadSavedAllergens()
        }
        .alert("Clear All", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllAllergens()
            }
        } message: {
            Text("Clear all selected allergens?")
        }
    }
    
    private var filteredAllergens: [String] {
        if searchText.isEmpty {
            return allAllergens
        } else {
            return allAllergens.filter { allergen in
                allergen.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func toggleAllergen(_ allergen: String) {
        if selectedAllergens.contains(allergen) {
            selectedAllergens.remove(allergen)
        } else {
            selectedAllergens.insert(allergen)
        }
    }
    
    private func loadSavedAllergens() {
        selectedAllergens = userAllergensManager.selectedAllergens
    }
    
    private func clearAllAllergens() {
        selectedAllergens.removeAll()
    }
}

struct AllergenRow: View {
    let allergen: String
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .blue : .gray)
            
            // Allergen name
            Text(allergen)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            // Generic allergen icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(red: 0.13, green: 0.13, blue: 0.14) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    MyAllergensView()
}
