//
//  DropZoneView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
	@ObservedObject var viewModel: ProjectScannerViewModel
	@State private var isTargeted = false
	
	var body: some View {
		VStack(spacing: 20) {
			Spacer()
			
			VStack(spacing: 16) {
				Image(systemName: isTargeted ? "arrow.down.circle.fill" : (viewModel.hasScannedWithNoResults ? "exclamationmark.triangle.fill" : "arrow.down.circle"))
					.font(.system(size: 60))
					.foregroundColor(isTargeted ? .accentColor : (viewModel.hasScannedWithNoResults ? .orange : .secondary))
					.symbolEffect(.bounce, value: isTargeted)
				
				if viewModel.hasScannedWithNoResults {
					Text("No Unity Projects Found")
						.font(.title2)
						.fontWeight(.semibold)
					
					VStack(spacing: 8) {
						Text("The scanned folder contains no Unity projects.")
							.font(.body)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
						
						HStack(spacing: 4) {
							Image(systemName: "folder")
								.font(.caption)
							Text(FormatHelper.formatPath(URL(fileURLWithPath: viewModel.selectedPath)))
								.font(.caption)
						}
						.foregroundColor(.secondary)
						.padding(.horizontal)
						.padding(.vertical, 4)
						.background(Color.secondary.opacity(0.1))
						.cornerRadius(6)
					}
					
					Text("Drop another folder here to try again")
						.font(.body)
						.foregroundColor(.secondary)
						.multilineTextAlignment(.center)
						.padding(.top, 8)
				} else {
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
			}
			.padding(40)
			.frame(maxWidth: 500)
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(isTargeted ? Color.accentColor.opacity(0.1) : (viewModel.hasScannedWithNoResults ? Color.orange.opacity(0.05) : Color.secondary.opacity(0.05)))
					.overlay(
						RoundedRectangle(cornerRadius: 16)
							.strokeBorder(
								isTargeted ? Color.accentColor : (viewModel.hasScannedWithNoResults ? Color.orange.opacity(0.5) : Color.secondary.opacity(0.3)),
								style: StrokeStyle(lineWidth: 2, dash: [8, 4])
							)
					)
			)
			.animation(.easeInOut(duration: 0.2), value: isTargeted)
			.animation(.easeInOut(duration: 0.2), value: viewModel.hasScannedWithNoResults)
			
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
