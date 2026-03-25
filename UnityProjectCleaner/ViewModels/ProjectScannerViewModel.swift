//
//  ProjectScannerViewModel.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import Foundation
import Combine

@MainActor
class ProjectScannerViewModel: ObservableObject {
	@Published var projects: [UnityProject] = []
	@Published var stats = CleaningStats()
	@Published var selectedPath: String = NSHomeDirectory()
	
	private let fileManager = FileManager.default
	private var scanningTask: Task<Void, Never>?
	
	// MARK: - Scanning
	
	func resetScan() {
		cancelScanning()
		projects.removeAll()
		stats = CleaningStats()
	}
	
	func scanForProjects() {
		// Cancel any existing scan
		scanningTask?.cancel()
		
		scanningTask = Task {
			stats.isScanning = true
			stats.currentOperation = "Scanning for Unity projects..."
			stats.scanProgress = 0.0
			projects.removeAll()
			
			await performScan()
			
			guard !Task.isCancelled else {
				stats.isScanning = false
				stats.currentOperation = "Scan cancelled"
				return
			}
			
			stats.isScanning = false
			stats.totalProjects = projects.count
			stats.scanProgress = 1.0
			updateStats()
			
			// Start calculating sizes
			await calculateAllSizes()
		}
	}
	
	func cancelScanning() {
		scanningTask?.cancel()
		stats.isScanning = false
		stats.isCalculating = false
		stats.isCleaning = false
		stats.currentOperation = "Cancelled"
	}
	
	private func performScan() async {
		let searchURL = URL(fileURLWithPath: selectedPath)
		var foundProjects: [UnityProject] = []
		var lastUpdateTime = Date()
		let updateInterval: TimeInterval = 0.5 // Update UI every 0.5 seconds
		
		// Use Task.detached to run on background thread
		await Task.detached(priority: .userInitiated) {
			guard let enumerator = self.fileManager.enumerator(
				at: searchURL,
				includingPropertiesForKeys: [.isDirectoryKey],
				options: [.skipsHiddenFiles]
			) else { return }
			
			for case let fileURL as URL in enumerator {
				// Check for cancellation
				if Task.isCancelled { break }
				
				// Skip common non-project folders
				let lastComponent = fileURL.lastPathComponent
				if ["Library", "Temp", "node_modules", ".git", "Build", "Builds"].contains(lastComponent) {
					enumerator.skipDescendants()
					continue
				}
				
				// Check if this is a Unity project
				if await self.isUnityProject(at: fileURL) {
					let project = UnityProject(path: fileURL)
					foundProjects.append(project)
					
					// Throttle UI updates
					let now = Date()
					if now.timeIntervalSince(lastUpdateTime) > updateInterval {
						await MainActor.run {
							self.projects = foundProjects
							self.stats.currentOperation = "Found \(foundProjects.count) projects: \(project.name)"
							self.stats.totalProjects = foundProjects.count
						}
						lastUpdateTime = now
					}
					
					// Skip descending into this project
					enumerator.skipDescendants()
				}
			}
			
			// Final update
			await MainActor.run {
				self.projects = foundProjects
			}
		}.value
	}
	
	private func isUnityProject(at url: URL) async -> Bool {
		let projectSettingsURL = url.appendingPathComponent("ProjectSettings")
		let projectVersionURL = projectSettingsURL.appendingPathComponent("ProjectVersion.txt")
		
		return fileManager.fileExists(atPath: projectVersionURL.path)
	}
	
	// MARK: - Size Calculation
	
	func calculateAllSizes() async {
		guard !projects.isEmpty else { return }
		
		stats.isCalculating = true
		stats.currentProjectIndex = 0
		stats.totalProjectsToProcess = projects.count
		
		for index in projects.indices {
			guard !Task.isCancelled else { break }
			
			stats.currentOperation = "Calculating: \(projects[index].name) (\(index + 1)/\(projects.count))"
			stats.currentProjectIndex = index + 1
			projects[index].isCalculatingSize = true
			
			let sizes = await calculateProjectSizes(for: projects[index])
			projects[index].sizeBeforeCleaning = sizes.before
			projects[index].cleanableSize = sizes.cleanable
			projects[index].isCalculatingSize = false
			
			updateStats()
		}
		
		stats.isCalculating = false
		stats.currentOperation = "Ready to clean"
		stats.currentProjectIndex = 0
		stats.totalProjectsToProcess = 0
	}
	
	private func recalculateSpecificProjects(_ projectsToRecalculate: [UnityProject]) async {
		guard !projectsToRecalculate.isEmpty else { return }
		
		stats.isCalculating = true
		stats.currentProjectIndex = 0
		stats.totalProjectsToProcess = projectsToRecalculate.count
		
		for (idx, project) in projectsToRecalculate.enumerated() {
			guard !Task.isCancelled else { break }
			
			// Find the project in our main array
			guard let projectIndex = projects.firstIndex(where: { $0.id == project.id }) else {
				continue
			}
			
			stats.currentOperation = "Recalculating: \(project.name) (\(idx + 1)/\(projectsToRecalculate.count))"
			stats.currentProjectIndex = idx + 1
			projects[projectIndex].isCalculatingSize = true
			
			let sizes = await calculateProjectSizes(for: projects[projectIndex])
			projects[projectIndex].sizeBeforeCleaning = sizes.before
			projects[projectIndex].cleanableSize = sizes.cleanable
			projects[projectIndex].isCalculatingSize = false
			
			updateStats()
		}
		
		stats.isCalculating = false
		stats.currentOperation = "Ready to clean"
		stats.currentProjectIndex = 0
		stats.totalProjectsToProcess = 0
	}
	
	private func calculateProjectSizes(for project: UnityProject) async -> (before: Int64, cleanable: Int64) {
		// Run size calculation on background thread
		return await Task.detached(priority: .userInitiated) {
			let totalSize = await self.fileManager.directorySize(at: project.path)
			let cleanableSize = await self.calculateCleanableSize(for: project)
			return (totalSize, cleanableSize)
		}.value
	}
	
	private func calculateCleanableSize(for project: UnityProject) async -> Int64 {
		var totalCleanable: Int64 = 0
		
		// Calculate cleanable folders
		for folder in UnityProject.cleanableFolders {
			guard !Task.isCancelled else { break }
			
			let folderURL = project.path.appendingPathComponent(folder)
			if fileManager.fileExists(atPath: folderURL.path) {
				totalCleanable += await fileManager.directorySize(at: folderURL)
			}
		}
		
		// Calculate cleanable files
		totalCleanable += await calculateCleanableFiles(in: project.path)
		
		return totalCleanable
	}
	
	private func calculateCleanableFiles(in directory: URL) async -> Int64 {
		var totalSize: Int64 = 0
		
		guard let enumerator = fileManager.enumerator(
			at: directory,
			includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) else { return 0 }
		
		for case let fileURL as URL in enumerator {
			guard !Task.isCancelled else { break }
			
			let fileName = fileURL.lastPathComponent
			
			// Skip if inside cleanable folders
			if UnityProject.cleanableFolders.contains(where: { fileURL.path.contains("/\($0)/") }) {
				continue
			}
			
			// Check if file matches cleanable patterns
			for pattern in UnityProject.cleanableFilePatterns {
				if fileName.hasSuffix(pattern) {
					if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
						totalSize += Int64(size)
					}
					break
				}
			}
		}
		
		return totalSize
	}
	
	// MARK: - Cleaning
	
	func cleanSelectedProjects() async -> CleaningResult {
		stats.isCleaning = true
		stats.currentProjectIndex = 0
		let selectedProjects = projects.filter { $0.isSelected }
		stats.totalProjectsToProcess = selectedProjects.count
		
		var result = CleaningResult()
		var cleanedProjects: [UnityProject] = []
		
		for (index, project) in selectedProjects.enumerated() {
			guard !Task.isCancelled else { break }
			
			stats.currentOperation = "Cleaning: \(project.name) (\(index + 1)/\(selectedProjects.count))"
			stats.currentProjectIndex = index + 1
			
			do {
				let freed = try await cleanProject(project)
				result.totalFreed += freed
				result.successfulProjects.append(project.name)
				cleanedProjects.append(project)
			} catch {
				// Continue cleaning other projects even if this one fails
				let errorMessage = error.localizedDescription
				result.failedProjects.append((name: project.name, error: errorMessage))
				print("Failed to clean \(project.name): \(errorMessage)")
			}
		}
		
		stats.isCleaning = false
		stats.currentProjectIndex = 0
		stats.totalProjectsToProcess = 0
		
		if result.wasSuccessful {
			stats.currentOperation = "✓ Cleaned \(result.successfulProjects.count) projects, freed \(FormatHelper.formatBytes(result.totalFreed))"
		} else {
			stats.currentOperation = "Cleaned \(result.successfulProjects.count) of \(selectedProjects.count) projects"
		}
		
		// Only recalculate the projects that were actually cleaned
		if !cleanedProjects.isEmpty {
			await recalculateSpecificProjects(cleanedProjects)
		}
		
		return result
	}
	
	private func cleanProject(_ project: UnityProject) async throws -> Int64 {
		return try await Task.detached(priority: .userInitiated) {
			var freedSpace: Int64 = 0
			var errors: [Error] = []
			
			// Remove cleanable folders
			for folder in UnityProject.cleanableFolders {
				guard !Task.isCancelled else { break }
				
				let folderURL = project.path.appendingPathComponent(folder)
				if self.fileManager.fileExists(atPath: folderURL.path) {
					do {
						let size = await self.fileManager.directorySize(at: folderURL)
						try self.fileManager.removeItem(at: folderURL)
						freedSpace += size
					} catch {
						// Log error but continue with other folders
						errors.append(error)
						print("Failed to remove \(folder) from \(project.name): \(error.localizedDescription)")
					}
				}
			}
			
			// Remove cleanable files
			do {
				freedSpace += try await self.removeCleanableFiles(in: project.path)
			} catch {
				errors.append(error)
			}
			
			// If we had errors but still freed some space, consider it a partial success
			// If we freed no space and had errors, throw an error
			if freedSpace == 0 && !errors.isEmpty {
				throw errors.first ?? NSError(
					domain: "ProjectCleaner",
					code: -1,
					userInfo: [NSLocalizedDescriptionKey: "Failed to clean project"]
				)
			}
			
			return freedSpace
		}.value
	}
	
	private func removeCleanableFiles(in directory: URL) async throws -> Int64 {
		var freedSpace: Int64 = 0
		
		guard let enumerator = fileManager.enumerator(
			at: directory,
			includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) else { return 0 }
		
		var filesToRemove: [(URL, Int64)] = []
		
		for case let fileURL as URL in enumerator {
			guard !Task.isCancelled else { break }
			
			let fileName = fileURL.lastPathComponent
			
			// Skip if inside cleanable folders (already removed)
			if UnityProject.cleanableFolders.contains(where: { fileURL.path.contains("/\($0)/") }) {
				continue
			}
			
			// Check if file matches cleanable patterns
			for pattern in UnityProject.cleanableFilePatterns {
				if fileName.hasSuffix(pattern) {
					if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
						filesToRemove.append((fileURL, Int64(size)))
					}
					break
				}
			}
		}
		
		// Remove files (continue even if some fail)
		for (fileURL, size) in filesToRemove {
			do {
				try fileManager.removeItem(at: fileURL)
				freedSpace += size
			} catch {
				// Log but continue
				print("Failed to remove file \(fileURL.lastPathComponent): \(error.localizedDescription)")
			}
		}
		
		return freedSpace
	}
	
	// MARK: - Selection Management
	
	func toggleSelection(for project: UnityProject) {
		if let index = projects.firstIndex(where: { $0.id == project.id }) {
			projects[index].isSelected.toggle()
			updateStats()
		}
	}
	
	func selectAll() {
		for index in projects.indices {
			projects[index].isSelected = true
		}
		updateStats()
	}
	
	func deselectAll() {
		for index in projects.indices {
			projects[index].isSelected = false
		}
		updateStats()
	}
	
	private func updateStats() {
		stats.totalProjects = projects.count
		stats.selectedProjects = projects.filter { $0.isSelected }.count
		stats.totalCleanableSize = projects.filter { $0.isSelected }.reduce(0) { $0 + $1.cleanableSize }
	}
}
