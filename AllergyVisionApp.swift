//
//  AllergyVisionApp.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI

@main
struct AllergyVisionApp: App {
    @State private var showLogo = true
    
    var body: some Scene {
        WindowGroup {
            if showLogo {
                LogoView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLogo = false
                    }
                }
            } else {
                ContentView()
            }
        }
    }
}
