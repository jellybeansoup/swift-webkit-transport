// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI

struct PayloadListView: View {

	var payloads: [Payload]

	var body: some View {
		ZStack {
			if payloads.isEmpty {
				Empty("No Payloads")
			}
			else {
				List {
					ForEach(payloads) { payload in
						NavigationLink(value: payload) {
							PayloadLinkView(payload: payload)
						}
					}
				}
				.listStyle(.plain)
				.navigationDestination(for: Payload.self) { payload in
					PayloadDetailView(payload: payload)
				}
			}
		}
		.navigationTitle("Payloads")
		.toolbarTitleDisplayMode(.inline)
	}
}

#Preview {

	NavigationStack {
		PayloadListView(
			payloads: [
				Payload(
					data: Data("""
						<!DOCTYPE html>
						<html lang="en">
						<head>
							<meta charset="utf-8">
							<title>Example</title>
						</head>
						<body>
							<h1>Hello world!</h1>
						</body>
						</html>
						""".utf8),
					response: HTTPURLResponse(
						url: URL(string: "https://example.com")!,
						statusCode: 200,
						httpVersion: "HTTP/1.1",
						headerFields: [
							"Content-Encoding": "gzip",
							"Content-Type": "text/html; charset=utf-8",
							"Date": "Sat, 01 Jan 2000 00:00:00 GMT",
						]
					)!
				)
			]
		)
	}

}
