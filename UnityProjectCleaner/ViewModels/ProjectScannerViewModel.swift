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
	@Published var sortOption: ProjectSortOption = .lastUsed
	@Published var sortAscending: Bool = false  // false = newest/largest first
	
	private let fileManager = FileManager.default
	private var scanningTask: Task<Void, Never>?
	
	// Concurrent queue for parallel processing
	private let processingQueue = DispatchQueue(label: "com.unitycleaner.processing", attributes: .concurrent)
	
	// Computed property for sorted projects
	var sortedProjects: [UnityProject] {
		let sorted: [UnityProject]
		
		switch sortOption {
		case .lastUsed:
			sorted = projects.sorted { sortAscending ? $0.lastModifiedDate < $1.lastModifiedDate : $0.lastModifiedDate > $1.lastModifiedDate }
		case .name:
			sorted = projects.sorted { sortAscending ? $0.name < $1.name : $0.name > $1.name }
		case .size:
			sorted = projects.sorted { sortAscending ? $0.sizeBeforeCleaning < $1.sizeBeforeCleaning : $0.sizeBeforeCleaning > $1.sizeBeforeCleaning }
		case .cleanable:
			sorted = projects.sorted { sortAscending ? $0.cleanableSize < $1.cleanableSize : $0.cleanableSize > $1.cleanableSize }
		}
		
		return sorted
	}
	
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
			calculateAllSizesInBackground()
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
		let updateInterval: TimeInterval = 0.5
		
		await Task.detached(priority: .userInitiated) {
			guard let enumerator = self.fileManager.enumerator(
				at: searchURL,
				includingPropertiesForKeys: [.isDirectoryKey],
				options: [.skipsHiddenFiles]
			) else { return }
			
			for case let fileURL as URL in enumerator {
				if Task.isCancelled { break }
				
				let lastComponent = fileURL.lastPathComponent
				if ["Library", "Temp", "node_modules", ".git", "Build", "Builds"].contains(lastComponent) {
					enumerator.skipDescendants()
					continue
				}
				
				if await self.isUnityProject(at: fileURL) {
					let project = UnityProject(path: fileURL)
					foundProjects.append(project)
					
					let now = Date()
					if now.timeIntervalSince(lastUpdateTime) > updateInterval {
						await MainActor.run {
							self.projects = foundProjects
							self.stats.currentOperation = "Found \(foundProjects.count) projects: \(project.name)"
							self.stats.totalProjects = foundProjects.count
						}
						lastUpdateTime = now
					}
					
					enumerator.skipDescendants()
				}
			}
			
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
	
	// MARK: - Size Calculation (True Parallel with DispatchQueue)
	
	private func calculateAllSizesInBackground() {
		Task.detached(priority: .userInitiated) { [weak self] in
			guard let self = self else { return }
			
			await MainActor.run {
				self.stats.isCalculating = true
				self.stats.currentProjectIndex = 0
				self.stats.totalProjectsToProcess = self.projects.count
				
				for index in self.projects.indices {
					self.projects[index].isCalculatingSize = true
				}
			}
			
			let projectsCopy = await MainActor.run { self.projects }
			
			// Use DispatchGroup for true parallelism
			let group = DispatchGroup()
			let lock = NSLock()
			var completedCount = 0
			
			for project in projectsCopy {
				if Task.isCancelled { break }
				
				group.enter()
				self.processingQueue.async {
					let sizes = self.calculateProjectSizesSync(for: project)
					
					// Update on main thread
					Task { @MainActor in
						if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
							self.projects[index].sizeBeforeCleaning = sizes.before
							self.projects[index].cleanableSize = sizes.cleanable
							self.projects[index].isCalculatingSize = false
							
							lock.lock()
							completedCount += 1
							let count = completedCount
							lock.unlock()
							
							self.stats.currentProjectIndex = count
							self.stats.currentOperation = "Calculating: \(self.projects[index].name) (\(count)/\(projectsCopy.count))"
							self.updateStats()
						}
					}
					
					group.leave()
				}
			}
			
			// Wait for all to complete
			group.wait()
			
			await MainActor.run {
				self.stats.isCalculating = false
				self.stats.currentOperation = "Ready to clean"
				self.stats.currentProjectIndex = 0
				self.stats.totalProjectsToProcess = 0
			}
		}
	}
	
	private func recalculateSpecificProjectsInBackground(_ projectsToRecalculate: [UnityProject]) {
		Task.detached(priority: .userInitiated) { [weak self] in
			guard let self = self else { return }
			guard !projectsToRecalculate.isEmpty else { return }
			
			await MainActor.run {
				self.stats.isCalculating = true
				self.stats.currentProjectIndex = 0
				self.stats.totalProjectsToProcess = projectsToRecalculate.count
				
				for project in projectsToRecalculate {
					if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
						self.projects[index].isCalculatingSize = true
					}
				}
			}
			
			let group = DispatchGroup()
			let lock = NSLock()
			var completedCount = 0
			
			for project in projectsToRecalculate {
				if Task.isCancelled { break }
				
				group.enter()
				self.processingQueue.async {
					let sizes = self.calculateProjectSizesSync(for: project)
					
					Task { @MainActor in
						if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
							self.projects[index].sizeBeforeCleaning = sizes.before
							self.projects[index].cleanableSize = sizes.cleanable
							self.projects[index].isCalculatingSize = false
							
							lock.lock()
							completedCount += 1
							let count = completedCount
							lock.unlock()
							
							self.stats.currentProjectIndex = count
							self.stats.currentOperation = "Recalculating: \(self.projects[index].name) (\(count)/\(projectsToRecalculate.count))"
							self.updateStats()
						}
					}
					
					group.leave()
				}
			}
			
			group.wait()
			
			await MainActor.run {
				self.stats.isCalculating = false
				self.stats.currentOperation = "Ready to clean"
				self.stats.currentProjectIndex = 0
				self.stats.totalProjectsToProcess = 0
			}
		}
	}
	
	// Synchronous calculation for use in DispatchQueue
	private nonisolated func calculateProjectSizesSync(for project: UnityProject) -> (before: Int64, cleanable: Int64) {
		let totalSize = fileManager.directorySizeSync(at: project.path)
		let cleanableSize = calculateCleanableSizeSync(for: project)
		return (totalSize, cleanableSize)
	}
	
	private nonisolated func calculateCleanableSizeSync(for project: UnityProject) -> Int64 {
		var totalCleanable: Int64 = 0
		
		// Calculate cleanable folders
		for folder in UnityProject.cleanableFolders {
			let folderURL = project.path.appendingPathComponent(folder)
			if fileManager.fileExists(atPath: folderURL.path) {
				totalCleanable += fileManager.directorySizeSync(at: folderURL)
			}
		}
		
		// Calculate cleanable files
		totalCleanable += calculateCleanableFilesSync(in: project.path)
		
		return totalCleanable
	}
	
	private nonisolated func calculateCleanableFilesSync(in directory: URL) -> Int64 {
		var totalSize: Int64 = 0
		
		guard let enumerator = fileManager.enumerator(
			at: directory,
			includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) else { return 0 }
		
		for case let fileURL as URL in enumerator {
			let fileName = fileURL.lastPathComponent
			
			if UnityProject.cleanableFolders.contains(where: { fileURL.path.contains("/\($0)/") }) {
				continue
			}
			
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
		
		if !cleanedProjects.isEmpty {
			recalculateSpecificProjectsInBackground(cleanedProjects)
		}
		
		return result
	}
	
	private func cleanProject(_ project: UnityProject) async throws -> Int64 {
		return try await Task.detached(priority: .userInitiated) {
			var freedSpace: Int64 = 0
			var errors: [Error] = []
			
			for folder in UnityProject.cleanableFolders {
				guard !Task.isCancelled else { break }
				
				let folderURL = project.path.appendingPathComponent(folder)
				if self.fileManager.fileExists(atPath: folderURL.path) {
					do {
						let size = self.fileManager.directorySizeSync(at: folderURL)
						try self.fileManager.removeItem(at: folderURL)
						freedSpace += size
					} catch {
						errors.append(error)
						print("Failed to remove \(folder) from \(project.name): \(error.localizedDescription)")
					}
				}
			}
			
			do {
				freedSpace += try self.removeCleanableFilesSync(in: project.path)
			} catch {
				errors.append(error)
			}
			
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
	
	private nonisolated func removeCleanableFilesSync(in directory: URL) throws -> Int64 {
		var freedSpace: Int64 = 0
		
		guard let enumerator = fileManager.enumerator(
			at: directory,
			includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) else { return 0 }
		
		var filesToRemove: [(URL, Int64)] = []
		
		for case let fileURL as URL in enumerator {
			let fileName = fileURL.lastPathComponent
			
			if UnityProject.cleanableFolders.contains(where: { fileURL.path.contains("/\($0)/") }) {
				continue
			}
			
			for pattern in UnityProject.cleanableFilePatterns {
				if fileName.hasSuffix(pattern) {
					if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
						filesToRemove.append((fileURL, Int64(size)))
					}
					break
				}
			}
		}
		
		for (fileURL, size) in filesToRemove {
			do {
				try fileManager.removeItem(at: fileURL)
				freedSpace += size
			} catch {
				print("Failed to remove file \(fileURL.lastPathComponent): \(error.localizedDescription)")
			}
		}
		
		return freedSpace
	}
	
	// MARK: - Selection Management
	
	func setSelection(for project: UnityProject, selected: Bool) {
		if let index = projects.firstIndex(where: { $0.id == project.id }) {
			projects[index].isSelected = selected
			updateStats()
		}
	}

	func selectProjectsMatching(_ predicate: (UnityProject) -> Bool) {
		// Set selection state for ALL projects based on predicate
		for index in projects.indices {
			projects[index].isSelected = predicate(projects[index])
		}
		updateStats()
	}

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

