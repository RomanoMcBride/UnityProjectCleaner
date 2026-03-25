//
//  ContentView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
	@StateObject private var viewModel = ProjectScannerViewModel()
	@State private var showingAlert = false
	@State private var alertTitle = ""
	@State private var alertMessage = ""
	
	var body: some View {
		VStack(spacing: 0) {
			// Header
			HeaderView(viewModel: viewModel)
			
			Divider()
			
			// Main content area
			if viewModel.projects.isEmpty && !viewModel.stats.isScanning {
				// Drop zone when no projects
				DropZoneView(viewModel: viewModel)
			} else {
				// Project List
				ProjectListView(viewModel: viewModel, scanRootPath: viewModel.selectedPath)
			}
			
			Divider()
			
			// Stats and Actions
			StatsView(
				viewModel: viewModel,
				onClean: cleanProjects
			)
		}
		.alert(alertTitle, isPresented: $showingAlert) {
			Button("OK", role: .cancel) { }
		} message: {
			Text(alertMessage)
		}
	}
	
	private func cleanProjects() {
		Task {
			let result = await viewModel.cleanSelectedProjects()
			
			if result.wasSuccessful {
				alertTitle = "✓ Cleaning Complete"
			} else if result.successfulProjects.isEmpty {
				alertTitle = "⚠️ Cleaning Failed"
			} else {
				alertTitle = "⚠️ Cleaning Partially Complete"
			}
			
			alertMessage = result.summary
			showingAlert = true
		}
	}
}

// MARK: - Header View

struct HeaderView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	
	var body: some View {
		VStack(spacing: 12) {
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text("Unity Project Cleaner")
						.font(.title)
						.fontWeight(.bold)
					
					// Show scanned path when we have projects
					if !viewModel.projects.isEmpty {
						HStack(spacing: 4) {
							Image(systemName: "folder")
								.font(.caption)
								.foregroundColor(.secondary)
							Text(FormatHelper.formatPath(URL(fileURLWithPath: viewModel.selectedPath)))
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				Spacer()
				
				if viewModel.stats.isScanning || viewModel.stats.isCalculating || viewModel.stats.isCleaning {
					Button("Cancel") {
						viewModel.cancelScanning()
					}
					.keyboardShortcut(.escape, modifiers: [])
				} else if !viewModel.projects.isEmpty {
					Button("Scan New Location") {
						viewModel.resetScan()
					}
					.keyboardShortcut("n", modifiers: .command)
				}
			}
			
			// Progress section
			if viewModel.stats.isScanning || viewModel.stats.isCalculating || viewModel.stats.isCleaning {
				VStack(spacing: 8) {
					HStack {
						Text(viewModel.stats.currentOperation)
							.font(.caption)
							.foregroundColor(.secondary)
							.lineLimit(1)
						
						Spacer()
						
						if viewModel.stats.totalProjectsToProcess > 0 {
							Text(viewModel.stats.progressPercentage)
								.font(.caption)
								.foregroundColor(.secondary)
								.monospacedDigit()
						}
					}
					
					ProgressView(
						value: viewModel.stats.totalProjectsToProcess > 0
							? Double(viewModel.stats.currentProjectIndex)
							: nil,
						total: Double(viewModel.stats.totalProjectsToProcess)
					)
					.progressViewStyle(.linear)
				}
			} else if !viewModel.stats.currentOperation.isEmpty && !viewModel.projects.isEmpty {
				HStack {
					Text(viewModel.stats.currentOperation)
						.font(.caption)
						.foregroundColor(.secondary)
					
					Spacer()
				}
			}
		}
		.padding()
	}
}

