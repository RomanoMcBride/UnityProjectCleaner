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
				ProjectListView(viewModel: viewModel)
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
				Text("Unity Project Cleaner")
					.font(.title)
					.fontWeight(.bold)
				
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
}

// MARK: - Drop Zone View

struct DropZoneView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	@State private var isTargeted = false
	
	var body: some View {
		VStack(spacing: 20) {
			Spacer()
			
			VStack(spacing: 16) {
				Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.down.circle")
					.font(.system(size: 60))
					.foregroundColor(isTargeted ? .accentColor : .secondary)
					.symbolEffect(.bounce, value: isTargeted)
				
				Text("Drag & Drop a Folder or Disk")
					.font(.title2)
					.fontWeight(.semibold)
				
				Text("Drop any folder or disk here to scan for Unity projects")
					.font(.body)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
				
				.font(.caption)
				.foregroundColor(.secondary)
				.padding(.top, 8)
			}
			.padding(40)
			.frame(maxWidth: 500)
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
					.overlay(
						RoundedRectangle(cornerRadius: 16)
							.strokeBorder(
								isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
								style: StrokeStyle(lineWidth: 2, dash: [8, 4])
							)
					)
			)
			.animation(.easeInOut(duration: 0.2), value: isTargeted)
			
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
			handleDrop(providers: providers)
			return true
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
