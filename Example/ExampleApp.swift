// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

@main
struct ExampleApp: App {

	var body: some Scene {
		WindowGroup {
			ContentView()
				#if os(macOS)
				.frame(minWidth: 480, minHeight: 320)
				#endif
		}
		.environment(\.transport, .live)
	}

}
