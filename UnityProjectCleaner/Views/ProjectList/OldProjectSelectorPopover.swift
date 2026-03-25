//
//  OldProjectSelectorPopover.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI

struct OldProjectSelectorPopover: View {
	@Binding var sliderValue: Double
	@Binding var showingDatePicker: Bool
	let oldestProjectDate: Date?
	let dateFromSlider: Date
	let projectsOlderThanDate: [UnityProject]
	let totalProjectCount: Int
	let onSelectProjects: (Date) -> Void
	
	var body: some View {
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
					Text("\(projectsOlderThanDate.count) of \(totalProjectCount) projects")
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
						onSelectProjects(dateFromSlider)
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
}
