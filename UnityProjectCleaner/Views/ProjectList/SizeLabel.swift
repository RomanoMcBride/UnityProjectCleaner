//
//  SizeLabel.swift
//  UnityProjectCleaner
//
//  Created by Ari Romano McBride on 3/25/26.
//


import SwiftUI

struct SizeLabel: View {
	let title: String
	let size: Int64
	let color: Color
	
	var body: some View {
		VStack(alignment: .trailing, spacing: 2) {
			Text(title)
				.font(.caption2)
				.foregroundColor(.secondary)
			
			Text(FormatHelper.formatBytes(size))
				.font(.system(.caption, design: .monospaced))
				.fontWeight(.medium)
				.foregroundColor(color)
		}
		.frame(minWidth: 80)
	}
}
