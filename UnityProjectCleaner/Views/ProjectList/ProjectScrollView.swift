//
//  ProjectScrollView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI
import UniformTypeIdentifiers

struct ProjectScrollView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	let scanRootPath: String
	@Binding var isTargeted: Bool
	let onDrop: ([NSItemProvider]) -> Void
	
	var body: some View {
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
			onDrop(providers)
			return true
		}
	}
}
