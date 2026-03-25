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
				
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
						Text("External drives")
					}
					HStack {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
						Text("Project folders")
					}
					HStack {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
						Text("Your home directory")
					}
				}
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
