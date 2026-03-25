//
//  FortmatHelpers.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation

struct FormatHelper {
	static func formatBytes(_ bytes: Int64) -> String {
		let formatter = ByteCountFormatter()
		formatter.countStyle = .file
		formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
		return formatter.string(fromByteCount: bytes)
	}
	
	static func formatPath(_ url: URL) -> String {
		let home = FileManager.default.homeDirectoryForCurrentUser.path
		let path = url.path
		
		if path.hasPrefix(home) {
			return "~" + path.dropFirst(home.count)
		}
		return path
	}
	
	static func formatRelativePath(_ url: URL, relativeTo base: URL) -> String? {
		let basePath = base.path
		let projectPath = url.path
		
		// Check if project is a direct child of the base
		if url.deletingLastPathComponent().path == basePath {
			return nil  // No path needed - it's in the root
		}
		
		// Get the relative path
		if projectPath.hasPrefix(basePath) {
			let relativePath = projectPath.dropFirst(basePath.count)
				.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
			
			// Remove the project name itself from the end
			if let range = relativePath.range(of: "/" + url.lastPathComponent) {
				return String(relativePath[..<range.lowerBound])
			}
			
			return String(relativePath)
		}
		
		return projectPath
	}
}

