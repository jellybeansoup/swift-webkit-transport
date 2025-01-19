// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation

/// Structure that represents the details of a XHR request performed within the `webView`.
struct Message: Decodable {

	let url: URL

	let status: Int

	let version: String

	let headers: [String: String]

	let body: Data

	var urlResponse: URLResponse? {
		HTTPURLResponse(
			url: url,
			statusCode: status,
			httpVersion: version,
			headerFields: headers
		)
	}

	// MARK: Decodable

	enum CodingKeys: CodingKey {
		case url
		case status
		case headers
		case body
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		var headers: [String: String] = [:]
		var version = "HTTP/1.1"
		for line in try container.decode(String.self, forKey: .headers).split(separator: "\r\n") {
			let components = line.split(separator: ":", omittingEmptySubsequences: false)

			let key: String
			let value: String
			if components.count == 2 {
				key = components[0].trimmingCharacters(in: .whitespaces)
				value = components[1].trimmingCharacters(in: .whitespaces)
			}
			else if components.count == 3, components[0].isEmpty {
				key = ":\(components[1].trimmingCharacters(in: .whitespaces))"
				value = components[2].trimmingCharacters(in: .whitespaces)
				version = "HTTP/2"
			}
			else {
				continue
			}

			headers[key] = value
		}

		self.url = try container.decode(URL.self, forKey: .url)
		self.status = try container.decode(Int.self, forKey: .status)
		self.headers = headers
		self.version = version
		self.body = Data(try container.decode(String.self, forKey: .body).utf8)
	}

}
