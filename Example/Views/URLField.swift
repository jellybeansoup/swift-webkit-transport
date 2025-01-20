// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct URLField: View {

	@State private var input: String

	@Binding private var url: URL?

	init(url: Binding<URL?>) {
		self._url = url
		self.input = url.wrappedValue?.absoluteString ?? ""
	}

	var body: some View {
		TextField("URL", text: $input, prompt: Text("Enter URL"))
			.textFieldStyle(.roundedBorder)
			#if os(iOS)
			.keyboardType(.URL)
			#endif
			.onSubmit(onSubmit)
	}

	private func onSubmit() {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

		guard let url = URL(string: trimmed) else {
			return
		}

		var components = URLComponents()
		components.fragment = url.fragment
		components.host = url.host
		components.password = url.password
		components.path = url.path
		components.port = url.port
		components.query = url.query
		components.scheme = url.scheme ?? "https"
		components.user = url.user

		if components.scheme == nil {
			components.scheme = "https"
		}

		if components.host == nil, components.path.isEmpty == false {
			var path = url.path.split(separator: "/")
			components.host = String(path.removeFirst())
			components.path = path.joined(separator: "/")
		}

		guard let url = components.url, self.url != url else {
			return
		}

		self.input = url.absoluteString
		self.url = url
	}

}

#Preview {

	NavigationStack {
		ScrollView {

		}
		.toolbar(removing: .title)
		.toolbar {
			ToolbarItem(placement: .principal) {
				URLField(url: .constant(nil))
			}
		}
	}

}
