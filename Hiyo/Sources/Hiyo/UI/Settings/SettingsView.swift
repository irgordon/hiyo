//
//  SettingsView.swift
//  Hiyo
//
//  Main settings container with tabbed interface.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .models
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ModelsSettings()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag(SettingsTab.models)
            
            PerformanceSettings()
                .tabItem {
                    Label("Performance", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(SettingsTab.performance)
            
            GeneralSettings()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)
            
            PrivacySettings()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
                .tag(SettingsTab.privacy)
        }
        .frame(width: 650, height: 480)
        .padding()
    }
    
    enum SettingsTab {
        case models, performance, general, privacy
    }
}
