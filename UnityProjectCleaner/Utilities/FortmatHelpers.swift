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
}
