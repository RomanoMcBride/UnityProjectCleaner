//
//  ProjectListView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	let scanRootPath: String
	@State private var isTargeted = false
	@State private var showingDatePicker = false
	@State private var sliderValue: Double = 0.5
	
	var body: some View {
		VStack(spacing: 0) {
			ProjectListToolbar(
				viewModel: viewModel,
				showingDatePicker: $showingDatePicker,
				sliderValue: $sliderValue,
				oldestProjectDate: oldestProjectDate,
				dateFromSlider: dateFromSlider,
				projectsOlderThanDate: projectsOlderThanDate,
				onSelectOldProjects: selectProjectsOlderThan
			)
			
			Divider()
			
			ProjectScrollView(
				viewModel: viewModel,
				scanRootPath: scanRootPath,
				isTargeted: $isTargeted,
				onDrop: handleDrop
			)
		}
	}
	
	// MARK: - Computed Properties
	
	private var oldestProjectDate: Date? {
		viewModel.projects
			.filter { $0.lastModifiedDate != Date.distantPast }
			.map { $0.lastModifiedDate }
			.min()
	}
	
	private var dateFromSlider: Date {
		guard let oldest = oldestProjectDate else { return Date() }
		let range = Date().timeIntervalSince(oldest)
		let offset = range * (1.0 - sliderValue)
		return Date().addingTimeInterval(-offset)
	}
	
	private var projectsOlderThanDate: [UnityProject] {
		viewModel.projects.filter { project in
			project.lastModifiedDate < dateFromSlider && project.lastModifiedDate != Date.distantPast
		}
	}
	
	// MARK: - Actions
	
	private func selectProjectsOlderThan(_ date: Date) {
		viewModel.selectProjectsMatching { project in
			project.lastModifiedDate < date && project.lastModifiedDate != Date.distantPast
		}
	}
	
	private func handleDrop(providers: [NSItemProvider]) {
		guard let provider = providers.first else { return }
		
		provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
			guard let data = item as? Data,
				  let url = URL(dataRepresentation: data, relativeTo: nil) else {
				return
			}
			
			DispatchQueue.main.async {
				var isDirectory: ObjCBool = false
				if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
				   isDirectory.boolValue {
					viewModel.selectedPath = url.path
					viewModel.scanForProjects()
				}
			}
		}
	}
}
