//
//  Intelligent_identificationApp.swift
//  Intelligent identification
//
//  Created by Jiahong Chen  on 10/24/25.
//

import SwiftUI

@main
struct Intelligent_identificationApp: App {
    @StateObject private var learningStore = LearningRecordStore()
    
    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(learningStore)
        }
    }
}

private struct RootContainerView: View {
    @AppStorage("hasCompletedPermissions") private var hasCompletedPermissions = false
    
    var body: some View {
        if hasCompletedPermissions {
            ContentView()
        } else {
            PermissionsOnboardingView(isCompleted: $hasCompletedPermissions)
        }
    }
}
