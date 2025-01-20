// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct Separator: View {

	@Environment(\.displayScale) var displayScale

	var body: some View {
		Rectangle()
			.fill(.primary.tertiary)
			.frame(height: 1 / displayScale)
	}

}
