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
	var lastModifiedDate: Date = Date.distantPast
	
	var sizeAfterCleaning: Int64 {
		return max(0, sizeBeforeCleaning - cleanableSize)
	}
	
	// Get cleanable folders from settings
	static var cleanableFolders: [String] {
		return CleaningSettings.shared.activeCleanableFolders
	}
	
	// Get cleanable file patterns from settings
	static var cleanableFilePatterns: [String] {
		return CleaningSettings.shared.activeCleanableFilePatterns
	}
	
	init(path: URL) {
		self.path = path
		self.name = path.lastPathComponent
		
		// Get last modified date from Library folder (most recently used) or project root
		let libraryPath = path.appendingPathComponent("Library")
		if let attributes = try? FileManager.default.attributesOfItem(atPath: libraryPath.path),
		   let modDate = attributes[.modificationDate] as? Date {
			self.lastModifiedDate = modDate
		} else if let attributes = try? FileManager.default.attributesOfItem(atPath: path.path),
				  let modDate = attributes[.modificationDate] as? Date {
			self.lastModifiedDate = modDate
		}
	}
	
	static func == (lhs: UnityProject, rhs: UnityProject) -> Bool {
		return lhs.id == rhs.id
	}
}

enum ProjectSortOption: String, CaseIterable {
	case lastUsed = "Last Used"
	case name = "Name"
	case size = "Size"
	case cleanable = "Cleanable"
	
	var systemImage: String {
		switch self {
		case .lastUsed: return "clock"
		case .name: return "textformat.abc"
		case .size: return "chart.bar"
		case .cleanable: return "trash"
		}
	}
}
