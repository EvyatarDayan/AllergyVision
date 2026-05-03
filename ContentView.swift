//
//  ContentView.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI
import MessageUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var selectedTab = 0
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        if isIPad {
            // Custom bottom tab bar for iPad
            VStack(spacing: 0) {
                // Main content
                Group {
                    switch selectedTab {
                    case 0:
                        ScanView()
                    case 1:
                        MyListView()
                    case 2:
                        HistoryView()
                    case 3:
                        SettingsView()
                    default:
                        ScanView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom bottom tab bar
                HStack(spacing: 0) {
                    TabButton(
                        title: "Scan",
                        icon: "barcode.viewfinder",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "My List",
                        icon: "heart",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: "History",
                        icon: "clock.arrow.circlepath",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabButton(
                        title: "Settings",
                        icon: "gearshape",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                }
                .frame(height: 80)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .top
                )
            }
            .background(Color.gray.opacity(0.1))
            .ignoresSafeArea(.all, edges: .all)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        } else {
            // Standard TabView for iPhone
            TabView {
                ScanView()
                    .tabItem {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
                
                MyListView()
                    .tabItem {
                        Label("My List", systemImage: "heart")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .background(Color.gray.opacity(0.1))
            .ignoresSafeArea(.all, edges: .all)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scan View
struct ScanView: View {
    @State private var isScanning = false
    
    var body: some View {
        ZStack {
            // Full background color
            Color.gray.opacity(0.1)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                    // Title
                    Text("Scan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                    
                    // Fixed space for scanner/icon (220 height to match scanner)
                    ZStack {
                        if isScanning {
                            // Show inline scanner
                            InlineScannerView(isScanning: $isScanning)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            // Show placeholder icon
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 100))
                                .foregroundColor(.blue)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(height: 220)
                    
                    Text("Scan Barcode")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 30)
                    
                    Text("Point your camera and scan barcode for allergens")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isScanning.toggle()
                        }
                    }) {
                        HStack(spacing: 12) {
//                            Image(systemName: isScanning ? "stop.circle.fill" : "camera.fill")
//                                .font(.system(size: 20))
                            Text(isScanning ? "Stop Scanning" : "Start Scanning")
                                .font(.headline)
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 260, height: 56)
                        .background(isScanning ? Color.red : Color.blue)
                        .cornerRadius(16)
                        .shadow(color: (isScanning ? Color.red : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.top, 80)
                .background(Color.clear)
            }
        }
    }

// MARK: - History View
struct HistoryView: View {
    @StateObject private var historyManager = ScanHistoryManager.shared
    @State private var selectedProduct: Product?
    @State private var showClearConfirmation = false
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Title
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                    
                    // Search bar - always show when there are items in the list
                    if !historyManager.scanHistory.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search history...", text: $searchText)
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
                        if historyManager.scanHistory.isEmpty {
                            // Empty state
                            VStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 10)
                                
                                Text("No Scan History")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Text("Your scanned products will appear here")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        } else if filteredHistory.isEmpty {
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
                            // History list
                            List {
                                ForEach(filteredHistory) { product in
                                    HistoryListItem(product: product)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedProduct = product
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    historyManager.removeProduct(product)
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
            .alert("Clear History", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        historyManager.clearHistory()
                    }
                }
            } message: {
                Text("Are you sure? all scan history will be deleted")
            }
        }
    }
    
    private var filteredHistory: [Product] {
        if searchText.isEmpty {
            return historyManager.scanHistory
        } else {
            return historyManager.scanHistory.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                (product.brands?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                product.barcode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - History List Item
struct HistoryListItem: View {
    let product: Product
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
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
                
                // Allergen indicator
                if product.hasAllergens {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("\(product.allergens.count) allergen\(product.allergens.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("No allergens information")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(colorScheme == .dark ? Color(red: 0.13, green: 0.13, blue: 0.14) : Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var showMyAllergens = false
    @State private var showTermsPrivacy = false
    @State private var showSupport = false
    @State private var showAbout = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Title
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                    
                    List {
                    Section(header: Text("Allergen Preferences")) {
                    Button(action: {
                        showMyAllergens = true
                    }) {
                        Text("My Allergens")
                    }
                    .foregroundColor(.primary)
                }
                
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                Section(header: Text("Legal")) {
                    Button(action: {
                        showTermsPrivacy = true
                    }) {
                        Text("Terms & Privacy")
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("Help & Support")) {
                    Button(action: {
                        showSupport = true
                    }) {
                        Text("Contact Us")
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("About")) {
                    Button(action: {
                        showAbout = true
                    }) {
                        Text("About App")
                    }
                    .foregroundColor(.primary)
                }
                    }
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                }
            .sheet(isPresented: $showMyAllergens) {
                MyAllergensView()
            }
            .sheet(isPresented: $showTermsPrivacy) {
                TermsPrivacyView()
            }
                .sheet(isPresented: $showSupport) {
                    ContactSupportView()
                }
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
        }
    }
}

// MARK: - Terms & Privacy View
struct TermsPrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Section", selection: $selectedTab) {
                    Text("Terms of Use").tag(0)
                    Text("Privacy Policy").tag(1)
                    Text("Disclaimer").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    TermsOfUseView()
                        .tag(0)
                    
                    PrivacyPolicyView()
                        .tag(1)
                    
                    DisclaimerView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Terms & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Terms of Use View
struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Use")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last updated: October 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By using the AllergyVision app, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.")
                        .font(.body)
                    
                    Text("2. Use of the App")
                        .font(.headline)
                    Text("The AllergyVision app is designed to help users identify potential allergens in food products by scanning barcodes. The app provides information based on data from OpenFoodFacts and other sources.")
                        .font(.body)
                    
                    Text("3. Accuracy of Information")
                        .font(.headline)
                    Text("While we strive to provide accurate allergen information, we cannot guarantee the completeness or accuracy of all data. Users should always verify information with product labels and consult healthcare professionals when necessary.")
                        .font(.body)
                    
                    Text("4. User Responsibilities")
                        .font(.headline)
                    Text("Users are responsible for their own health decisions and should not rely solely on the app for allergen information. Always read product labels and consult with healthcare providers for medical advice.")
                        .font(.body)
                    
                    Text("5. Limitation of Liability")
                        .font(.headline)
                    Text("The app is provided 'as is' without warranties of any kind. We shall not be liable for any damages arising from the use of this app.")
                        .font(.body)
                }
            }
            .padding()
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last updated: October 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Information We Collect")
                        .font(.headline)
                    Text("We collect scan history and allergen preferences that you voluntarily provide. This data is stored locally on your device and is not transmitted to external servers.")
                        .font(.body)
                    
                    Text("2. How We Use Information")
                        .font(.headline)
                    Text("Your scan history and allergen preferences are used solely to provide personalized allergen warnings and improve your app experience.")
                        .font(.body)
                    
                    Text("3. Data Storage")
                        .font(.headline)
                    Text("All personal data is stored locally on your device using iOS UserDefaults. We do not collect, store, or transmit personal information to external servers.")
                        .font(.body)
                    
                    Text("4. Third-Party Services")
                        .font(.headline)
                    Text("The app uses the OpenFoodFacts API to retrieve product information. We do not share your personal data with third parties.")
                        .font(.body)
                    
                    Text("5. Your Rights")
                        .font(.headline)
                    Text("You can clear your scan history and allergen preferences at any time through the app settings. All data can be deleted by uninstalling the app.")
                        .font(.body)
                }
            }
            .padding()
        }
    }
}

// MARK: - Disclaimer View
struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Disclaimer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last updated: October 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medical Disclaimer")
                        .font(.headline)
                    Text("The AllergyVision app is for informational purposes only and is not intended to replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding food allergies.")
                        .font(.body)
                    
                    Text("Data Accuracy")
                        .font(.headline)
                    Text("While we strive to provide accurate allergen information, product formulations may change. Always read current product labels and contact manufacturers for the most up-to-date allergen information.")
                        .font(.body)
                    
                    Text("No Warranty")
                        .font(.headline)
                    Text("The app is provided 'as is' without any warranties, express or implied. We disclaim all warranties including merchantability, fitness for a particular purpose, and non-infringement.")
                        .font(.body)
                    
                    Text("Limitation of Liability")
                        .font(.headline)
                    Text("In no event shall the app developers be liable for any direct, indirect, incidental, special, or consequential damages arising out of the use or inability to use the app.")
                        .font(.body)
                    
                    Text("Emergency Situations")
                        .font(.headline)
                    Text("This app is not designed for emergency situations. If you experience an allergic reaction, seek immediate medical attention or call emergency services.")
                        .font(.body)
                }
        }
        .padding()
        }
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var showingValidationAlert = false
    @State private var isSending = false // not used with Mail, kept for UI consistency if needed
    @State private var showMailComposer = false
    @State private var showResultAlert = false
    @State private var resultAlertMessage = ""
    @State private var attemptedSend = false
    
    private let maxSubjectLength = 100
    private let maxMessageLength = 400
    
    var body: some View {
        NavigationView {
            Form {
                // Full name
                Section(header: Text("YOUR FULL NAME")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Full Name", text: $name)
                            .textContentType(.name)
                            .autocapitalization(.words)
                    }
                    if attemptedSend && !isValidFullName(name) {
                        Text("Please enter your full name")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Email
                Section(header: Text("YOUR EMAIL")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    if attemptedSend && !isValidEmail(email) {
                        Text("Invalid email address")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Subject with counter inside bottom-right
                Section(header: Text("SUBJECT")) {
                    TextField("How can we help?", text: $subject)
                        .onChange(of: subject) { newValue in
                            if newValue.count > maxSubjectLength {
                                subject = String(newValue.prefix(maxSubjectLength))
                            }
                        }
                }
                
                // Description with placeholder and counter inside
                Section(header: Text("DESCRIPTION")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 200)
                        .onChange(of: message) { newValue in
                            if newValue.count > maxMessageLength {
                                message = String(newValue.prefix(maxMessageLength))
                            }
                        }
                }
                
                // Send button
                Section {
                    Button(action: sendEmail) {
                        Text("Send")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(fieldsFilled ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                    // Keep enabled to allow validations to show after first tap
                    .disabled(false)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Contact us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Please complete all fields", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposer(
                    toRecipients: ["abashelariprod@gmail.com"],
                    subject: buildEmailSubject(),
                    body: buildEmailBody()
                ) { result in
                    switch result {
                    case .sent:
                        resultAlertMessage = "Thanks! Your message was sent."
                    case .saved:
                        resultAlertMessage = "Draft saved in Mail."
                    case .failed:
                        resultAlertMessage = "We couldn't send the email. Please try again."
                    case .cancelled:
                        resultAlertMessage = "Email cancelled."
                    }
                    showResultAlert = true
                }
            }
            .alert(resultAlertMessage, isPresented: $showResultAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private var canSend: Bool {
        isValidFullName(name) &&
        isValidEmail(email) &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var fieldsFilled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: email)
    }

    private func isValidFullName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        return parts.count >= 2 && parts.allSatisfy { $0.count >= 2 }
    }
    
    private func sendEmail() {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        attemptedSend = true
        guard canSend else { return }
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback to mailto link
            let to = "abashelariprod@gmail.com"
            let subjectEncoded = buildEmailSubject().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bodyEncoded = buildEmailBody().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
            if let url = URL(string: urlString) { openURL(url) }
            resultAlertMessage = "Your Mail app was opened. Please review and send your email."
            showResultAlert = true
        }
    }

    private func buildEmailSubject() -> String { subject }
    private func buildEmailBody() -> String {
        "Name: \(name)\nEmail: \(email)\n\nMessage:\n\(message)"
    }
}

// MARK: - Mail Composer Wrapper
struct MailComposer: UIViewControllerRepresentable {
    enum ComposeResult { case sent, saved, cancelled, failed }
    var toRecipients: [String]
    var subject: String
    var body: String
    var onFinish: (ComposeResult) -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (ComposeResult) -> Void
        init(onFinish: @escaping (ComposeResult) -> Void) { self.onFinish = onFinish }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let mapped: ComposeResult
            switch result {
            case .sent: mapped = .sent
            case .saved: mapped = .saved
            case .cancelled: mapped = .cancelled
            case .failed: mapped = .failed
            @unknown default: mapped = .failed
            }
            controller.dismiss(animated: true) { self.onFinish(mapped) }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About AllergyVision")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    Text("AllergyVision helps you scan product barcodes to quickly identify potential allergens. It combines OpenFoodFacts data with enhanced detection and translation to present ingredients and allergen warnings clearly in English.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("About Abashelari Software")
                        .font(.headline)
                    Text("Abashelari Software focuses on crafting simple, privacy-respecting mobile experiences. Your data stays on your device; we do not collect scan history or personal information.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Privacy-first design", systemImage: "lock")
                        Label("Clear allergen warnings", systemImage: "exclamationmark.triangle")
                        Label("OpenFoodFacts integration", systemImage: "barcode.viewfinder")
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer(minLength: 10)
                    Text("Thank you for using AllergyVision.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
