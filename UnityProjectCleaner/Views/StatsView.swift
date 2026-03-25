//
//  StatsView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import SwiftUI

struct StatsView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	let onClean: () -> Void
	
	@State private var showingConfirmation = false
	
	var body: some View {
		VStack(spacing: 12) {
			// Statistics
			HStack(spacing: 24) {
				StatItem(
					label: "Total Projects",
					value: "\(viewModel.stats.totalProjects)"
				)
				
				StatItem(
					label: "Selected",
					value: "\(viewModel.stats.selectedProjects)"
				)
				
				Spacer()
				
				VStack(alignment: .trailing, spacing: 4) {
					Text("Total Cleanable Space")
						.font(.caption)
						.foregroundColor(.secondary)
					
					Text(FormatHelper.formatBytes(viewModel.stats.totalCleanableSize))
						.font(.title2)
						.fontWeight(.bold)
						.foregroundColor(viewModel.stats.totalCleanableSize > 0 ? .red : .secondary)
				}
			}
			
			// Action button
			Button(action: {
				showingConfirmation = true
			}) {
				HStack {
					if viewModel.stats.isCleaning {
						ProgressView()
							.scaleEffect(0.7)
							.frame(width: 16, height: 16)
					}
					Label("Clean Selected Projects", systemImage: "trash")
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 8)
			}
			.buttonStyle(.borderedProminent)
			.disabled(!viewModel.stats.canClean || viewModel.stats.totalCleanableSize == 0)
			.confirmationDialog(
				"Are you sure?",
				isPresented: $showingConfirmation,
				titleVisibility: .visible
			) {
				Button("Clean \(viewModel.stats.selectedProjects) Projects", role: .destructive) {
					onClean()
				}
				Button("Cancel", role: .cancel) { }
			} message: {
				Text("This will permanently delete \(FormatHelper.formatBytes(viewModel.stats.totalCleanableSize)) of regeneratable files from \(viewModel.stats.selectedProjects) projects.")
			}
		}
		.padding()
	}
}

// MARK: - Stat Item

struct StatItem: View {
	let label: String
	let value: String
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(label)
				.font(.caption)
				.foregroundColor(.secondary)
			
			Text(value)
				.font(.title3)
				.fontWeight(.semibold)
		}
	}
}
