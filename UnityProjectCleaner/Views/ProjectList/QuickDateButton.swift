//
//  QuickDateButton.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI

struct QuickDateButton: View {
	let title: String
	let months: Int
	let oldest: Date
	@Binding var sliderValue: Double
	
	var body: some View {
		Button(title) {
			let targetDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
			let range = Date().timeIntervalSince(oldest)
			let offset = Date().timeIntervalSince(targetDate)
			sliderValue = max(0, min(1, 1.0 - (offset / range)))
		}
		.buttonStyle(.bordered)
		.controlSize(.small)
	}
}
