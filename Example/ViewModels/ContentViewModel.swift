// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation
import WebKitTransport

@Observable
final class ContentViewModel {

	var url: URL?

	var payloads: [Payload]

	var isLoading = false

	var size: CGSize?

	init(
		url: URL? = nil,
		payloads: [Payload] = []
	) {
		self.url = url
		self.payloads = payloads
	}

	func load() async {
		payloads = []
		isLoading = true

		defer {
			isLoading = false
		}

		guard let url else {
			return
		}

		do {
			for await (data, response) in try await WebKitTask.load(url) {
				payloads.append(
					Payload(
						data: data,
						response: response,
						relativeTo: url
					)
				)
			}
		}
		catch {
			print(error)
		}
	}

}
