//
//  FileManagerExtensions.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation

extension FileManager {
	func directorySize(at url: URL) async -> Int64 {
		var totalSize: Int64 = 0
		
		guard let enumerator = self.enumerator(
			at: url,
			includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) else { return 0 }
		
		for case let fileURL as URL in enumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
				  let isRegularFile = resourceValues.isRegularFile,
				  isRegularFile,
				  let fileSize = resourceValues.fileSize else {
				continue
			}
			
			totalSize += Int64(fileSize)
		}
		
		return totalSize
	}
}
