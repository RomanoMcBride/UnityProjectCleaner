//
//  UnityProjectCleanerApp.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import SwiftUI

@main
struct UnityProjectCleanerApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
				.frame(minWidth: 900, minHeight: 600)
		}
		.windowStyle(.hiddenTitleBar)
		.windowResizability(.contentSize)
		
		// Preferences window
		Settings {
			PreferencesView()
		}
	}
}
