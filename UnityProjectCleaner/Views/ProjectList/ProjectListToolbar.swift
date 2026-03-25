//
//  ProjectListToolbar.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI

struct ProjectListToolbar: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	@Binding var showingDatePicker: Bool
	@Binding var sliderValue: Double
	let oldestProjectDate: Date?
	let dateFromSlider: Date
	let projectsOlderThanDate: [UnityProject]
	let onSelectOldProjects: (Date) -> Void
	
	var body: some View {
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
				initializeSlider()
				showingDatePicker.toggle()
			}) {
				Label("Last Opened Before...", systemImage: "calendar.badge.clock")
			}
			.popover(isPresented: $showingDatePicker, arrowEdge: .bottom) {
				OldProjectSelectorPopover(
					sliderValue: $sliderValue,
					showingDatePicker: $showingDatePicker,
					oldestProjectDate: oldestProjectDate,
					dateFromSlider: dateFromSlider,
					projectsOlderThanDate: projectsOlderThanDate,
					totalProjectCount: viewModel.projects.count,
					onSelectProjects: onSelectOldProjects
				)
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
	}
	
	private func initializeSlider() {
		guard let oldest = oldestProjectDate else { return }
		let range = Date().timeIntervalSince(oldest)
		let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
		let offset = Date().timeIntervalSince(sixMonthsAgo)
		sliderValue = 1.0 - (offset / range)
	}
}
