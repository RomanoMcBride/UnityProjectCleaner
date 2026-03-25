//
//  ContentView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//

import SwiftUI

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
			
			// Project List
			ProjectListView(viewModel: viewModel)
			
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
				Text("Unity Project Cleaner")
					.font(.title)
					.fontWeight(.bold)
				
				Spacer()
			}
			
			HStack(spacing: 12) {
				TextField("Scan path", text: $viewModel.selectedPath)
					.textFieldStyle(.roundedBorder)
					.disabled(viewModel.stats.isScanning)
				
				Button("Browse...") {
					selectFolder()
				}
				.disabled(viewModel.stats.isScanning)
				
				if viewModel.stats.isScanning || viewModel.stats.isCalculating || viewModel.stats.isCleaning {
					Button("Cancel") {
						viewModel.cancelScanning()
					}
					.keyboardShortcut(.escape, modifiers: [])
				} else {
					Button("Scan") {
						viewModel.scanForProjects()
					}
					.keyboardShortcut("r", modifiers: .command)
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
			} else if !viewModel.stats.currentOperation.isEmpty {
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
	
	private func selectFolder() {
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.allowsMultipleSelection = false
		
		if panel.runModal() == .OK, let url = panel.url {
			viewModel.selectedPath = url.path
		}
	}
}
