// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI
import WebKitTransport

struct ContentView: View {

	@State private var url: URL?

	@State private var payloads: [Payload]

	@State private var isLoading = false

	@State private var size: CGSize?

	@State private var task: Task<Void, Never>?

	@Environment(\.transport) private var transport

	init(
		url: URL? = nil,
		payloads: [Payload] = []
	) {
		self.url = url
		self.payloads = payloads
	}

	var body: some View {
		GeometryReader { proxy in
			NavigationSplitView(
				columnVisibility: .constant(.doubleColumn),
				sidebar: {
					#if !os(macOS)
					// When in a collapsed state, this list is displayed,
					// and navigation occurs directly to the detail.
					PayloadListView(payloads: payloads)
						.toolbar(removing: .sidebarToggle)
						.toolbar { toolbar(width: proxy.size.width) }
					#else
					// This ensures we cannot display the sidebar
					VStack {}.toolbar(removing: .sidebarToggle)
					#endif
				},
				content: {
					PayloadListView(payloads: payloads)
						#if !os(macOS)
						.toolbar { toolbar(width: proxy.size.width) }
						#endif
				},
				detail: {
					Empty("No Selection")
				}
			)
			#if os(macOS)
			.toolbar { toolbar(width: proxy.size.width) }
			#endif
		}
		.toolbar(removing: .title)
		.toolbarTitleDisplayMode(.inlineLarge)
		.onChange(of: url) { _, _ in loadPayloads() }
		.onDisappear { task?.cancel() }
	}

	@ToolbarContentBuilder
	func toolbar(width: CGFloat) -> some ToolbarContent {
		ToolbarItem(placement: .principal) {
			URLField(url: $url)
				#if os(macOS)
				.frame(minWidth: 290, idealWidth: width * 0.6)
				#endif
		}

		ToolbarItem(placement: .primaryAction) {
			Button(
				action: loadPayloads,
				label: {
					Label("Reload", systemImage: "arrow.clockwise")
				}
			)
			.disabled(url == nil || isLoading)
		}
	}

	func loadPayloads() {
		guard let url else {
			return
		}

		task?.cancel()
		task = Task {
			payloads = []
			isLoading = true

			defer { isLoading = false }

			do {
				for try await payload in transport.load(url) {
					payloads.append(payload)
				}
			}
			catch {
				
			}
		}
	}

}

#Preview {
	ContentView(
		url: URL(string: "https://example.com"),
		payloads: Payload.previews
	)
}

#Preview("Empty State") {
	ContentView()
}
