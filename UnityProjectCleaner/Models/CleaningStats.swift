//
//  CleaningStats.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation

struct CleaningStats {
	var totalProjects: Int = 0
	var selectedProjects: Int = 0
	var totalCleanableSize: Int64 = 0
	var isScanning: Bool = false
	var isCalculating: Bool = false
	var isCleaning: Bool = false
	var currentOperation: String = ""
	var scanProgress: Double = 0.0  // 0.0 to 1.0
	var currentProjectIndex: Int = 0
	var totalProjectsToProcess: Int = 0
	
	var canClean: Bool {
		return selectedProjects > 0 && !isScanning && !isCalculating && !isCleaning
	}
	
	var progressPercentage: String {
		if totalProjectsToProcess > 0 {
			let percentage = (Double(currentProjectIndex) / Double(totalProjectsToProcess)) * 100
			return String(format: "%.0f%%", percentage)
		}
		return ""
	}
}

struct CleaningResult {
	var successfulProjects: [String] = []
	var failedProjects: [(name: String, error: String)] = []
	var totalFreed: Int64 = 0
	
	var wasSuccessful: Bool {
		return failedProjects.isEmpty
	}
	
	var summary: String {
		var message = ""
		
		if !successfulProjects.isEmpty {
			message += "✓ Successfully cleaned \(successfulProjects.count) project(s)\n"
			message += "Freed: \(FormatHelper.formatBytes(totalFreed))\n"
		}
		
		if !failedProjects.isEmpty {
			message += "\n⚠️ Failed to clean \(failedProjects.count) project(s):\n"
			for (name, error) in failedProjects {
				message += "  • \(name): \(error)\n"
			}
			message += "\nTip: Try running the app with administrator privileges or check file permissions."
		}
		
		if successfulProjects.isEmpty && failedProjects.isEmpty {
			message = "No projects were cleaned."
		}
		
		return message
	}
}
