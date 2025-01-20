// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI
import WebKitTransport

struct ContentView: View {

	@State private var viewModel: ContentViewModel

	@State private var task: Task<Void, Never>?

	init(viewModel: ContentViewModel = .init()) {
		self.viewModel = viewModel
	}

	var body: some View {
		GeometryReader { proxy in
			NavigationSplitView(
				columnVisibility: .constant(.doubleColumn),
				sidebar: {
					#if !os(macOS)
					// When in a collapsed state, this list is displayed,
					// and navigation occurs directly to the detail.
					PayloadListView(payloads: viewModel.payloads)
						.toolbar(removing: .sidebarToggle)
						.toolbar { toolbar(width: proxy.size.width) }
					#else
					// This ensures we cannot display the sidebar
					VStack {}.toolbar(removing: .sidebarToggle)
					#endif
				},
				content: {
					PayloadListView(payloads: viewModel.payloads)
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
		.onChange(of: viewModel.url) { _, _ in
			task = Task { await viewModel.load() }
		}
		.onDisappear {
			task?.cancel()
		}
	}

	@ToolbarContentBuilder
	func toolbar(width: CGFloat) -> some ToolbarContent {
		ToolbarItem(placement: .principal) {
			URLField(url: $viewModel.url)
				#if os(macOS)
				.frame(minWidth: 290, idealWidth: width * 0.6)
				#endif
		}

		ToolbarItem(placement: .primaryAction) {
			Button {
				task = Task { await viewModel.load() }
			} label: {
				Label("Reload", systemImage: "arrow.clockwise")
			}
			.disabled(viewModel.isLoading)
		}
	}

}

#Preview {
	ContentView(
		viewModel: .init(
			url: URL(string: "https://example.com"),
			payloads: Payload.previews
		)
	)
}

#Preview("Empty State") {
	ContentView(
		viewModel: .init()
	)
}
