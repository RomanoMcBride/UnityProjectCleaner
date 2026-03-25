//
//  PreferencesView.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI

struct PreferencesView: View {
	@ObservedObject var settings = CleaningSettings.shared
	@State private var newFolderName = ""
	@State private var newPatternName = ""
	@State private var showingResetAlert = false
	
	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				Text("Cleaning Preferences")
					.font(.title2)
					.fontWeight(.bold)
				
				Spacer()
				
				Button("Reset to Defaults") {
					showingResetAlert = true
				}
			}
			.padding()
			
			Divider()
			
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					// Folders Section
					VStack(alignment: .leading, spacing: 12) {
						Text("Folders to Remove")
							.font(.headline)
						
						Text("Select which folders should be removed when cleaning projects")
							.font(.caption)
							.foregroundColor(.secondary)
						
						VStack(alignment: .leading, spacing: 8) {
							ForEach(settings.allAvailableFolders, id: \.self) { folder in
								HStack {
									Toggle(isOn: Binding(
										get: { settings.enabledFolders.contains(folder) },
										set: { _ in settings.toggleFolder(folder) }
									)) {
										HStack(spacing: 8) {
											// Type indicator icon
											if settings.isUserPreferenceFolder(folder) {
												Image(systemName: "person.fill")
													.foregroundColor(.orange)
													.help("User Preferences")
											} else if settings.isCustomFolder(folder) {
												Image(systemName: "star.fill")
													.foregroundColor(.purple)
													.help("Custom")
											} else {
												Image(systemName: "checkmark.shield.fill")
													.foregroundColor(.green)
													.help("Safe to Remove")
											}
											
											Image(systemName: "folder.fill")
												.foregroundColor(.blue)
											
											Text(folder)
												.font(.system(.body, design: .monospaced))
											
											if settings.isCustomFolder(folder) {
												Spacer()
												Button(action: {
													settings.removeCustomFolder(folder)
												}) {
													Image(systemName: "xmark.circle.fill")
														.foregroundColor(.secondary)
												}
												.buttonStyle(.plain)
												.help("Remove custom folder")
											}
										}
									}
									.toggleStyle(.checkbox)
								}
							}
						}
						
						// Add custom folder
						HStack {
							TextField("Add custom folder...", text: $newFolderName)
								.textFieldStyle(.roundedBorder)
								.onSubmit {
									addCustomFolder()
								}
							
							Button("Add") {
								addCustomFolder()
							}
							.disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
						}
					}
					
					Divider()
					
					// File Patterns Section
					VStack(alignment: .leading, spacing: 12) {
						Text("File Patterns to Remove")
							.font(.headline)
						
						Text("Select which file types should be removed when cleaning projects")
							.font(.caption)
							.foregroundColor(.secondary)
						
						VStack(alignment: .leading, spacing: 8) {
							ForEach(settings.allAvailableFilePatterns, id: \.self) { pattern in
								HStack {
									Toggle(isOn: Binding(
										get: { settings.enabledFilePatterns.contains(pattern) },
										set: { _ in settings.toggleFilePattern(pattern) }
									)) {
										HStack(spacing: 8) {
											// Type indicator icon
											if settings.isCustomFilePattern(pattern) {
												Image(systemName: "star.fill")
													.foregroundColor(.purple)
													.help("Custom")
											} else {
												Image(systemName: "checkmark.shield.fill")
													.foregroundColor(.green)
													.help("Safe to Remove")
											}
											
											Image(systemName: "doc.fill")
												.foregroundColor(.gray)
											
											Text(pattern)
												.font(.system(.body, design: .monospaced))
											
											if settings.isCustomFilePattern(pattern) {
												Spacer()
												Button(action: {
													settings.removeCustomFilePattern(pattern)
												}) {
													Image(systemName: "xmark.circle.fill")
														.foregroundColor(.secondary)
												}
												.buttonStyle(.plain)
												.help("Remove custom pattern")
											}
										}
									}
									.toggleStyle(.checkbox)
								}
							}
						}
						
						// Add custom pattern
						HStack {
							TextField("Add custom pattern (e.g., .log)...", text: $newPatternName)
								.textFieldStyle(.roundedBorder)
								.onSubmit {
									addCustomPattern()
								}
							
							Button("Add") {
								addCustomPattern()
							}
							.disabled(newPatternName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
						}
					}
					
					Divider()
					
					// Info section / Legend
					VStack(alignment: .leading, spacing: 8) {
						Text("Legend")
							.font(.caption)
							.fontWeight(.semibold)
							.foregroundColor(.secondary)
						
						HStack(spacing: 8) {
							Image(systemName: "checkmark.shield.fill")
								.foregroundColor(.green)
							Text("Safe to Remove")
								.font(.caption)
						}
						Text("These items can be regenerated by Unity or your IDE")
							.font(.caption2)
							.foregroundColor(.secondary)
							.padding(.leading, 24)
						
						HStack(spacing: 8) {
							Image(systemName: "person.fill")
								.foregroundColor(.orange)
							Text("User Preferences")
								.font(.caption)
						}
						.padding(.top, 4)
						Text("Contains your editor preferences and window layouts")
							.font(.caption2)
							.foregroundColor(.secondary)
							.padding(.leading, 24)
						
						HStack(spacing: 8) {
							Image(systemName: "star.fill")
								.foregroundColor(.purple)
							Text("Custom")
								.font(.caption)
						}
						.padding(.top, 4)
						Text("Items you've added yourself")
							.font(.caption2)
							.foregroundColor(.secondary)
							.padding(.leading, 24)
					}
					.padding(.top, 8)
				}
				.padding()
			}
		}
		.frame(width: 600, height: 500)
		.alert("Reset to Defaults?", isPresented: $showingResetAlert) {
			Button("Cancel", role: .cancel) { }
			Button("Reset", role: .destructive) {
				settings.resetToDefaults()
			}
		} message: {
			Text("This will restore all cleaning options to their default settings and remove any custom folders or patterns you've added.")
		}
	}
	
	private func addCustomFolder() {
		settings.addCustomFolder(newFolderName)
		newFolderName = ""
	}
	
	private func addCustomPattern() {
		settings.addCustomFilePattern(newPatternName)
		newPatternName = ""
	}
}

struct PreferencesView_Previews: PreviewProvider {
	static var previews: some View {
		PreferencesView()
	}
}

