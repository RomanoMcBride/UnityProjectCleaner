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
	@State private var sliderValue: Double = 0.5  // 0 = oldest, 1 = today
	
	var body: some View {
		VStack(spacing: 0) {
			// Control buttons
			HStack(spacing: 12) {
				Button("Select All") {
					viewModel.selectAll()
				}
				.keyboardShortcut("a", modifiers: .command)
				
				Button("Deselect All") {
					viewModel.deselectAll()
				}
				.keyboardShortcut("d", modifiers: .command)
				
				// Date-based selection
				Button(action: {
					// Initialize slider to 6 months ago when opening
					if let oldest = oldestProjectDate {
						let range = Date().timeIntervalSince(oldest)
						let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
						let offset = Date().timeIntervalSince(sixMonthsAgo)
						sliderValue = 1.0 - (offset / range)
					}
					showingDatePicker.toggle()
				}) {
					Label("Select Old Projects...", systemImage: "calendar.badge.clock")
				}
				.popover(isPresented: $showingDatePicker, arrowEdge: .bottom) {
					VStack(alignment: .leading, spacing: 16) {
						Text("Select projects not opened since:")
							.font(.headline)
						
						if let oldest = oldestProjectDate {
							VStack(spacing: 12) {
								// Date display
								HStack {
									Text(dateFromSlider.formatted(date: .abbreviated, time: .omitted))
										.font(.title3)
										.fontWeight(.semibold)
									
									Spacer()
									
									Text("(\(dateFromSlider, style: .relative))")
										.font(.caption)
										.foregroundColor(.secondary)
								}
								
								// Slider
								VStack(alignment: .leading, spacing: 4) {
									Slider(value: $sliderValue, in: 0...1)
									
									HStack {
										Text(oldest.formatted(date: .abbreviated, time: .omitted))
											.font(.caption2)
											.foregroundColor(.secondary)
										
										Spacer()
										
										Text(Date().formatted(date: .abbreviated, time: .omitted))
											.font(.caption2)
											.foregroundColor(.secondary)
									}
								}
								
								// Quick selection buttons
								HStack(spacing: 8) {
									QuickDateButton(title: "1 month", months: -1, oldest: oldest, sliderValue: $sliderValue)
									QuickDateButton(title: "3 months", months: -3, oldest: oldest, sliderValue: $sliderValue)
									QuickDateButton(title: "6 months", months: -6, oldest: oldest, sliderValue: $sliderValue)
									QuickDateButton(title: "1 year", months: -12, oldest: oldest, sliderValue: $sliderValue)
								}
							}
							.padding(.vertical, 8)
							
							Divider()
							
							HStack {
								Text("\(projectsOlderThanDate.count) of \(viewModel.projects.count) projects")
									.font(.caption)
									.foregroundColor(.secondary)
								
								if !projectsOlderThanDate.isEmpty {
									Text("•")
										.foregroundColor(.secondary)
										.font(.caption)
									
									let totalCleanable = projectsOlderThanDate.reduce(0) { $0 + $1.cleanableSize }
									Text(FormatHelper.formatBytes(totalCleanable))
										.font(.caption)
										.foregroundColor(.red)
								}
								
								Spacer()
								
								Button("Cancel") {
									showingDatePicker = false
								}
								.keyboardShortcut(.escape, modifiers: [])
								
								Button("Select") {
									selectProjectsOlderThan(dateFromSlider)
									showingDatePicker = false
								}
								.buttonStyle(.borderedProminent)
								.keyboardShortcut(.return, modifiers: [])
								.disabled(projectsOlderThanDate.isEmpty)
							}
						} else {
							Text("No projects with dates found")
								.foregroundColor(.secondary)
								.padding()
						}
					}
					.padding()
					.frame(width: 400)
				}
				
				Divider()
					.frame(height: 20)
				
				// Sort controls
				Text("Sort by:")
					.font(.caption)
					.foregroundColor(.secondary)
				
				Picker("", selection: $viewModel.sortOption) {
					ForEach(ProjectSortOption.allCases, id: \.self) { option in
						Label(option.rawValue, systemImage: option.systemImage)
							.tag(option)
					}
				}
				.pickerStyle(.segmented)
				.frame(width: 320)
				
				Button(action: {
					viewModel.sortAscending.toggle()
				}) {
					Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
						.imageScale(.medium)
				}
				.buttonStyle(.borderless)
				.help(viewModel.sortAscending ? "Ascending" : "Descending")
				
				Spacer()
			}
			.padding(.horizontal)
			.padding(.vertical, 8)
			
			Divider()
			
			// Projects table with drop zone overlay
			ZStack {
				ScrollView {
					LazyVStack(spacing: 0) {
						ForEach(viewModel.sortedProjects) { project in
							ProjectRowView(
								project: project,
								scanRootURL: URL(fileURLWithPath: scanRootPath),
								onToggle: {
									viewModel.toggleSelection(for: project)
								}
							)
							Divider()
						}
					}
				}
				
				// Overlay drop zone when dragging
				if isTargeted {
					VStack(spacing: 12) {
						Image(systemName: "arrow.down.circle.fill")
							.font(.system(size: 40))
							.foregroundColor(.accentColor)
						
						Text("Drop to scan new location")
							.font(.headline)
							.foregroundColor(.primary)
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
							.padding(20)
					)
				}
			}
			.onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
				handleDrop(providers: providers)
				return true
			}
		}
	}
	
	// Get oldest project date
	private var oldestProjectDate: Date? {
		viewModel.projects
			.filter { $0.lastModifiedDate != Date.distantPast }
			.map { $0.lastModifiedDate }
			.min()
	}
	
	// Convert slider value to date
	private var dateFromSlider: Date {
		guard let oldest = oldestProjectDate else { return Date() }
		let range = Date().timeIntervalSince(oldest)
		let offset = range * (1.0 - sliderValue)
		return Date().addingTimeInterval(-offset)
	}
	
	// Computed property to get projects older than selected date
	private var projectsOlderThanDate: [UnityProject] {
		viewModel.projects.filter { project in
			project.lastModifiedDate < dateFromSlider && project.lastModifiedDate != Date.distantPast
		}
	}
	
	// Select projects older than date
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
