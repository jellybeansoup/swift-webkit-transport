// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct PayloadLinkView: View {

	var payload: Payload

	var body: some View {
		HStack {
			Image(systemName: payload.iconName)
				.renderingMode(.original)

			VStack(alignment: .leading) {
				Text(payload.name)
					.lineLimit(1)

				if let location = payload.location {
					Text(location)
						.lineLimit(1)
						.font(.subheadline)
						.foregroundStyle(Color.secondary)
				}
			}
		}
		.symbolVariant(payload.isMainDocument ? .fill : .none)
		.imageScale(.large)
		.padding(3)
	}

}

#Preview {

	List {
		Section("Payloads") {
			ForEach(Payload.previews) { payload in
				PayloadLinkView(payload: payload)
			}
		}
	}
	.listStyle(.plain)

}
