//
//  MacDiskCleanerApp.swift
//  MacDiskCleaner
//
//  Created by  Kalpesh on 07/07/26.
//

import SwiftUI

@main
struct MacDiskCleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
