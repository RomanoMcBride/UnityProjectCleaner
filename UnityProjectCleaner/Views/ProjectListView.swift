//
//  ProjectListView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import SwiftUI

struct ProjectListView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	
	var body: some View {
		VStack(spacing: 0) {
			// Control buttons
			HStack {
				Button("Select All") {
					viewModel.selectAll()
				}
				.keyboardShortcut("a", modifiers: .command)
				
				Button("Deselect All") {
					viewModel.deselectAll()
				}
				.keyboardShortcut("d", modifiers: .command)
				
				Spacer()
				
				Text("\(viewModel.projects.count) projects found")
					.font(.caption)
					.foregroundColor(.secondary)
			}
			.padding(.horizontal)
			.padding(.vertical, 8)
			
			Divider()
			
			// Projects table
			if viewModel.projects.isEmpty {
				VStack {
					Spacer()
					Text("No Unity projects found")
						.foregroundColor(.secondary)
					Text("Click 'Scan' to search for projects")
						.font(.caption)
						.foregroundColor(.secondary)
					Spacer()
				}
			} else {
				ScrollView {
					LazyVStack(spacing: 0) {
						ForEach(viewModel.projects) { project in
							ProjectRowView(
								project: project,
								onToggle: {
									viewModel.toggleSelection(for: project)
								}
							)
							Divider()
						}
					}
				}
			}
		}
	}
}

// MARK: - Project Row View

struct ProjectRowView: View {
	let project: UnityProject
	let onToggle: () -> Void
	
	var body: some View {
		HStack(spacing: 12) {
			// Checkbox
			Button(action: onToggle) {
				Image(systemName: project.isSelected ? "checkmark.square.fill" : "square")
					.foregroundColor(project.isSelected ? .accentColor : .secondary)
					.imageScale(.large)
			}
			.buttonStyle(.plain)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(project.name)
					.font(.system(.body, design: .default))
					.fontWeight(.medium)
				
				Text(FormatHelper.formatPath(project.path))
					.font(.caption)
					.foregroundColor(.secondary)
					.lineLimit(1)
			}
			
			Spacer()
			
			if project.isCalculatingSize {
				ProgressView()
					.scaleEffect(0.7)
			} else {
				VStack(alignment: .trailing, spacing: 4) {
					HStack(spacing: 16) {
						SizeLabel(
							title: "Current",
							size: project.sizeBeforeCleaning,
							color: .secondary
						)
						
						SizeLabel(
							title: "Can Remove",
							size: project.cleanableSize,
							color: project.cleanableSize > 0 ? .red : .secondary
						)
						
						SizeLabel(
							title: "After",
							size: project.sizeAfterCleaning,
							color: .green
						)
					}
				}
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 12)
		.contentShape(Rectangle())
		.onTapGesture {
			onToggle()
		}
	}
}

// MARK: - Size Label

struct SizeLabel: View {
	let title: String
	let size: Int64
	let color: Color
	
	var body: some View {
		VStack(alignment: .trailing, spacing: 2) {
			Text(title)
				.font(.caption2)
				.foregroundColor(.secondary)
			
			Text(FormatHelper.formatBytes(size))
				.font(.system(.caption, design: .monospaced))
				.fontWeight(.medium)
				.foregroundColor(color)
		}
		.frame(minWidth: 80)
	}
}
