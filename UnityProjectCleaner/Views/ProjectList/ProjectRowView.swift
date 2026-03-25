//
//  ProjectRowView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI

struct ProjectRowView: View {
	let project: UnityProject
	let scanRootURL: URL
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
				
				HStack(spacing: 8) {
					// Show relative path only if project is in a subfolder
					if let relativePath = FormatHelper.formatRelativePath(project.path, relativeTo: scanRootURL) {
						Text(relativePath)
							.font(.caption)
							.foregroundColor(.secondary)
							.lineLimit(1)
						
						Text("•")
							.foregroundColor(.secondary)
							.font(.caption)
					}
					
					if project.lastModifiedDate != Date.distantPast {
						Text(project.lastModifiedDate, style: .relative)
							.font(.caption)
							.foregroundColor(.secondary)
					}
				}
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
		.contextMenu {
			Button(action: {
				showInFinder()
			}) {
				Label("Show in Finder", systemImage: "folder.badge.gearshape")
			}
			
			Button(action: {
				copyPath()
			}) {
				Label("Copy Path", systemImage: "doc.on.doc")
			}
			
			Divider()
			
			Button(action: onToggle) {
				if project.isSelected {
					Label("Deselect", systemImage: "square")
				} else {
					Label("Select", systemImage: "checkmark.square")
				}
			}
		}
	}
	
	private func showInFinder() {
		NSWorkspace.shared.selectFile(project.path.path, inFileViewerRootedAtPath: project.path.deletingLastPathComponent().path)
	}
	
	private func copyPath() {
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.setString(project.path.path, forType: .string)
	}
}
