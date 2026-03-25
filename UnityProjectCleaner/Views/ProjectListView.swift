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
	@State private var isTargeted = false
	
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
			
			// Projects table with drop zone overlay
			ZStack {
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
