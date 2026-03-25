//
//  CleaningStats.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation

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
