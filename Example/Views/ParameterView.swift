// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct ParameterView: View {

	var label: String

	var value: Any?

	var body: some View {
		ViewThatFits {
			HStack(alignment: .firstTextBaseline) {
				labelView
				valueView
			}

			VStack(alignment: .leading) {
				labelView
				valueView
			}
		}
	}

	var labelView: some View {
		Text("\(label): ")
			.foregroundStyle(Color.secondary)
			.lineLimit(1)
	}

	var valueView: some View {
		Text(verbatim: value.map(String.init(describing:)) ?? "—")
			.foregroundStyle(Color.primary)
	}

}

struct ParameterViewPreview: View {

	var body: some View {
		ParameterView(
			label: "Example",
			value: "This is an example value"
		)

		ParameterView(
			label: "Multi-line Example",
			value: "This is an example of a really long value that might wrap over multiple lines. There's a good chance that this will need to be dealt with in a slightly different fasion to those that are shorter."
		)

		ParameterView(
			label: "Numeric Example",
			value: 123_456_789
		)

		ParameterView(
			label: "Empty Example",
			value: nil
		)
	}

}

#Preview("VStack") {

	ScrollView {
		VStack(alignment: .leading) {
			ParameterViewPreview()
		}
		.padding(8)
		.frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
	}

}

#Preview("List") {

	List {
		ParameterViewPreview()
	}

}
