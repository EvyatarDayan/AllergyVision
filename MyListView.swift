//
//  MyListView.swift
//  AllergyVision
//

import SwiftUI

struct MyListView: View {
    @StateObject private var shoppingListManager = ShoppingListManager.shared
    @State private var searchText = ""
    @State private var showClearConfirmation = false
    @State private var selectedProduct: Product?
    
    var filteredShoppingList: [Product] {
        if searchText.isEmpty {
            return shoppingListManager.shoppingList
        } else {
            return shoppingListManager.shoppingList.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                (product.brands?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Title
                    Text("My List")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                    
                    // Search bar - always show when there are items in the list
                    if !shoppingListManager.shoppingList.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search your list...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .submitLabel(.done)
                                .foregroundColor(.primary)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.top, 30)
                    }
                    
                    // Content area - fixed position regardless of content
                    VStack {
                        if shoppingListManager.shoppingList.isEmpty {
                            // Empty state
                            VStack {
                                Image(systemName: "heart")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 10)
                                
                                Text("No Shopping List")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Text("Add products to your shopping list by tapping the heart icon in product details")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        } else if filteredShoppingList.isEmpty {
                            // No search results
                            VStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 10)
                                
                                Text("No Results Found")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Text("Try a different search term")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 20)
                        } else {
                            // Shopping list
                            List {
                                ForEach(filteredShoppingList) { product in
                                    ShoppingListItem(product: product)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedProduct = product
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    shoppingListManager.removeFromShoppingList(product)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                            }
                            .listStyle(.plain)
                            .background(Color.clear)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailsView(product: product)
            }
            .alert("Clear Shopping List", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        shoppingListManager.clearShoppingList()
                    }
                }
            } message: {
                Text("Are you sure? all items will be removed")
            }
        }
    }
}

// MARK: - Shopping List Item
struct ShoppingListItem: View {
    let product: Product
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var shoppingListManager = ShoppingListManager.shared
    
    private var isCompleted: Bool {
        shoppingListManager.isCompleted(product)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button(action: {
                shoppingListManager.toggleCompleted(product)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Product Image
            if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    case .failure:
                        Image("GenericProduct")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Placeholder when no image
                Image("GenericProduct")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .strikethrough(isCompleted)
                
                // Allergen indicator
                if product.hasAllergens {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isCompleted ? .gray : .red)
                        Text("\(product.allergens.count) allergen\(product.allergens.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(isCompleted ? .gray : .red)
                            .fontWeight(.medium)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isCompleted ? .gray : .orange)
                        Text("No allergens information")
                            .font(.caption)
                            .foregroundColor(isCompleted ? .gray : .orange)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
            // Heart icon (filled since it's in the list)
            Image(systemName: "heart.fill")
                .font(.system(size: 16))
                .foregroundColor(isCompleted ? .gray : .red)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(colorScheme == .dark ? Color(red: 0.13, green: 0.13, blue: 0.14) : Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    MyListView()
}
