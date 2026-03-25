//
//  UnityProject.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation

struct UnityProject: Identifiable, Equatable {
	let id = UUID()
	let path: URL
	let name: String
	var isSelected: Bool = true
	var sizeBeforeCleaning: Int64 = 0
	var cleanableSize: Int64 = 0
	var isCalculatingSize: Bool = false
	
	var sizeAfterCleaning: Int64 {
		return sizeBeforeCleaning - cleanableSize
	}
	
	// Folders that can be safely deleted
	static let cleanableFolders = [
		"Library",
		"Temp",
		"obj",
		"Logs",
		"MemoryCaptures",
		".vs",
		".vscode",
		"Build",
		"Builds"
	]
	
	// Files that can be safely deleted
	static let cleanableFilePatterns = [
		//".csproj",
		//".sln",
		".suo",
		".user",
		//".userprefs",
		".pidb",
		".booproj",
		".unityproj",
		".DS_Store"
	]
	
	init(path: URL) {
		self.path = path
		self.name = path.lastPathComponent
	}
	
	static func == (lhs: UnityProject, rhs: UnityProject) -> Bool {
		return lhs.id == rhs.id
	}
}
