// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation

struct Payload: Hashable, Identifiable {

	var id: UUID

	var data: Data

	var response: URLResponse

	var baseURL: URL?

	var iconName: String {
		switch mimeType {
		case "text/html": "richtext.page"
		case "application/octet-stream": "questionmark.text.page"
		default: "text.page"
		}
	}

	var name: String {
		if let filename = response.suggestedFilename, filename.isEmpty == false, filename != "Unknown" {
			return filename
		}
		else if let responseURL = response.url, responseURL.lastPathComponent.isEmpty == false {
			return responseURL.lastPathComponent
		}
		else {
			return "Payload"
		}
	}

	var location: String? {
		guard let responseURL = response.url else {
			return nil
		}

		guard
			let baseURL,
			let relativeURL = URL(string: responseURL.absoluteString, relativeTo: baseURL),
			relativeURL.relativePath.isEmpty == false
		else {
			return responseURL.absoluteString
		}

		return relativeURL.relativePath
	}

	init(data: Data, response: URLResponse, relativeTo baseURL: URL? = nil) {
		self.id = .init()
		self.data = data
		self.response = response
		self.baseURL = baseURL
	}

	var mimeType: String {
		response.mimeType ?? "application/octet-stream"
	}

	var statusCode: Int? {
		(response as? HTTPURLResponse)?.statusCode
	}

	var headers: [(key: String, value: Any)]? {
		(response as? HTTPURLResponse)?.allHeaderFields
			.map { (key: String(describing: $0.key), value: $0.value) }
			.sorted { $0.key < $1.key }
	}

	var body: String {
		String(data: data, encoding: .utf8) ?? ""
	}

	var isMainDocument: Bool {
		response.url == baseURL
	}

}
