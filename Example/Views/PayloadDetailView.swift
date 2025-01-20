// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct PayloadDetailView: View {

	var payload: Payload

	enum Tab: Hashable {
		case body
		case headers
		case preview
	}

	@State var tab: Tab = .body

	var body: some View {
		tabView
			.safeAreaInset(edge: .top, spacing: 0) {
				VStack(spacing: 0) {
					VStack(alignment: .leading) {
						ParameterView(
							label: "URL",
							value: payload.response.url?.absoluteString
						)

						ParameterView(
							label: "Status",
							value: payload.statusCode
						)

						ParameterView(
							label: "Mime-Type",
							value: payload.response.mimeType
						)

						ParameterView(
							label: "Encoding",
							value: payload.response.textEncodingName
						)

						Picker("Tab", selection: $tab) {
							Text("Body").tag(Tab.body)

							if payload.headers != nil {
								Text("Headers").tag(Tab.headers)
							}

							if payload.mimeType == "text/html" {
								Text("Preview").tag(Tab.preview)
							}
						}
						.labelsHidden()
						.pickerStyle(.segmented)
					}
					.padding(8)
					.frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)

					Rectangle()
						.fill(Color.primary.tertiary)
						.frame(height: 1)
				}
				.background(Material.bar)
			}
			.navigationTitle(payload.name)
			.toolbarTitleDisplayMode(.inline)
	}

	@ViewBuilder
	var tabView: some View {
		switch tab {
		case .body:
			ScrollView {
				VStack(alignment: .leading) {
					Text(verbatim: payload.body)
						.multilineTextAlignment(.leading)
				}
				.padding(8)
				.frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
			}

		case .headers:
			List {
				ForEach(payload.headers ?? [], id: \.key) { key, value in
					ParameterView(
						label: String(describing: key),
						value: value
					)
				}
			}

		case .preview:
			WebView(payload: payload)
				.onChange(of: payload.mimeType) { _, newValue in
					if newValue != "text/html" {
						tab = .body
					}
				}
		}
	}

}

#Preview {

	NavigationStack {

		PayloadDetailView(
			payload: Payload.previews[1]
		)

	}

}
