// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct Empty: View {

	var message: String

	init(_ message: String) {
		self.message = message
	}

	var body: some View {
		Text(message)
			.font(.title2)
			.foregroundStyle(Color.secondary.tertiary)
	}

}
