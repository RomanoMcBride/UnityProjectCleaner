//
//  CleaningSettings.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation
import Combine

import Foundation
import Combine

class CleaningSettings: ObservableObject {
	static let shared = CleaningSettings()
	
	// Folders that can be regenerated identically
	static let regeneratableFolders = [
		"Library",
		"Temp",
		"obj",
		".vs",
		".vscode"
	]
	
	// Build output and logs (generated but not identical)
	static let buildOutputFolders = [
		"Logs",
		"MemoryCaptures",
		"Build",
		"Builds",
		"Recordings"
	]
	
	// User preference folders (safe but user might want to keep)
	static let userPreferenceFolders = [
		"UserSettings"  // Unity user preferences (window layouts, etc.)
	]
	
	// All default folders combined
	static let defaultCleanableFolders = regeneratableFolders + buildOutputFolders
	
	// File patterns that can be regenerated
	static let defaultCleanableFilePatterns = [
		".csproj",
		".sln",
		".suo",
		".user",
		".userprefs",
		".pidb",
		".booproj",
		".unityproj",
		".DS_Store"
	]
	
	@Published var enabledFolders: Set<String>
	@Published var enabledFilePatterns: Set<String>
	@Published var customFolders: [String]
	@Published var customFilePatterns: [String]
	
	private let enabledFoldersKey = "enabledFolders"
	private let enabledFilePatternsKey = "enabledFilePatterns"
	private let customFoldersKey = "customFolders"
	private let customFilePatternsKey = "customFilePatterns"
	
	private init() {
		// Load from UserDefaults or use defaults
		if let savedFolders = UserDefaults.standard.array(forKey: enabledFoldersKey) as? [String] {
			self.enabledFolders = Set(savedFolders)
		} else {
			// Default: all default folders enabled, user preference folders disabled
			self.enabledFolders = Set(Self.defaultCleanableFolders)
		}
		
		if let savedPatterns = UserDefaults.standard.array(forKey: enabledFilePatternsKey) as? [String] {
			self.enabledFilePatterns = Set(savedPatterns)
		} else {
			self.enabledFilePatterns = Set(Self.defaultCleanableFilePatterns)
		}
		
		self.customFolders = UserDefaults.standard.array(forKey: customFoldersKey) as? [String] ?? []
		self.customFilePatterns = UserDefaults.standard.array(forKey: customFilePatternsKey) as? [String] ?? []
	}
	
	// Get all folders that should be cleaned
	var activeCleanableFolders: [String] {
		let allFolders = Self.defaultCleanableFolders + Self.userPreferenceFolders + customFolders
		return allFolders.filter { enabledFolders.contains($0) }
	}
	
	// Get all file patterns that should be cleaned
	var activeCleanableFilePatterns: [String] {
		let allPatterns = Self.defaultCleanableFilePatterns + customFilePatterns
		return allPatterns.filter { enabledFilePatterns.contains($0) }
	}
	
	// All available folders (for UI)
	var allAvailableFolders: [String] {
		return Self.regeneratableFolders + Self.buildOutputFolders + Self.userPreferenceFolders + customFolders
	}
	
	// All available patterns (for UI)
	var allAvailableFilePatterns: [String] {
		return Self.defaultCleanableFilePatterns + customFilePatterns
	}
	
	// Save settings
	func save() {
		UserDefaults.standard.set(Array(enabledFolders), forKey: enabledFoldersKey)
		UserDefaults.standard.set(Array(enabledFilePatterns), forKey: enabledFilePatternsKey)
		UserDefaults.standard.set(customFolders, forKey: customFoldersKey)
		UserDefaults.standard.set(customFilePatterns, forKey: customFilePatternsKey)
	}
	
	// Toggle folder
	func toggleFolder(_ folder: String) {
		if enabledFolders.contains(folder) {
			enabledFolders.remove(folder)
		} else {
			enabledFolders.insert(folder)
		}
		save()
	}
	
	// Toggle file pattern
	func toggleFilePattern(_ pattern: String) {
		if enabledFilePatterns.contains(pattern) {
			enabledFilePatterns.remove(pattern)
		} else {
			enabledFilePatterns.insert(pattern)
		}
		save()
	}
	
	// Add custom folder
	func addCustomFolder(_ folder: String) {
		let trimmed = folder.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty, !allAvailableFolders.contains(trimmed) else { return }
		customFolders.append(trimmed)
		enabledFolders.insert(trimmed)
		save()
	}
	
	// Add custom file pattern
	func addCustomFilePattern(_ pattern: String) {
		let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty, !allAvailableFilePatterns.contains(trimmed) else { return }
		customFilePatterns.append(trimmed)
		enabledFilePatterns.insert(trimmed)
		save()
	}
	
	// Remove custom folder
	func removeCustomFolder(_ folder: String) {
		customFolders.removeAll { $0 == folder }
		enabledFolders.remove(folder)
		save()
	}
	
	// Remove custom file pattern
	func removeCustomFilePattern(_ pattern: String) {
		customFilePatterns.removeAll { $0 == pattern }
		enabledFilePatterns.remove(pattern)
		save()
	}
	
	// Reset to defaults
	func resetToDefaults() {
		enabledFolders = Set(Self.defaultCleanableFolders)
		enabledFilePatterns = Set(Self.defaultCleanableFilePatterns)
		customFolders = []
		customFilePatterns = []
		save()
	}
	
	// Categorization helpers
	func isRegeneratableFolder(_ folder: String) -> Bool {
		return Self.regeneratableFolders.contains(folder)
	}
	
	func isBuildOutputFolder(_ folder: String) -> Bool {
		return Self.buildOutputFolders.contains(folder)
	}
	
	func isUserPreferenceFolder(_ folder: String) -> Bool {
		return Self.userPreferenceFolders.contains(folder)
	}
	
	func isCustomFolder(_ folder: String) -> Bool {
		return customFolders.contains(folder)
	}
	
	func isCustomFilePattern(_ pattern: String) -> Bool {
		return customFilePatterns.contains(pattern)
	}
}
