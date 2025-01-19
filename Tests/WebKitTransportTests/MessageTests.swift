// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation
import Testing
@testable import WebKitTransport

@Suite struct MessageTests {

	@Test("Decode HTTP/1.1 message")
	func decodeHTTP1_1Message() throws {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"status": 200,
				"headers": "Content-Type: text/html\\r\\nContent-Length: 42",
				"body": "Hello world!"
			}
			""".utf8)

		let message = try JSONDecoder().decode(Message.self, from: data)

		#expect(message.url == URL(string: "https://example.com/test"))
		#expect(message.status == 200)
		#expect(message.version == "HTTP/1.1")
		#expect(message.headers.count == 2)
		#expect(message.headers["Content-Type"] == "text/html")
		#expect(message.headers["Content-Length"] == "42")
		#expect(String(decoding: message.body, as: UTF8.self) == "Hello world!")

		let urlResponse = try #require(message.urlResponse as? HTTPURLResponse)

		#expect(urlResponse.url == URL(string: "https://example.com/test"))
		#expect(urlResponse.statusCode == 200)
		#expect(urlResponse.value(forHTTPHeaderField: "Content-Type") == "text/html")
		#expect(urlResponse.value(forHTTPHeaderField: "Content-Length") == "42")
	}

	@Test("Decode HTTP/2 message")
	func decodeHTTP2Message() throws {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"status": 404,
				"headers": "Content-Type: text/plain\\r\\n:status: 404",
				"body": "Not Found"
			}
			""".utf8)

		let message = try JSONDecoder().decode(Message.self, from: data)

		#expect(message.url == URL(string: "https://example.com/test"))
		#expect(message.status == 404)
		#expect(message.version == "HTTP/2")
		#expect(message.headers.count == 2)
		#expect(message.headers["Content-Type"] == "text/plain")
		#expect(message.headers[":status"] == "404")
		#expect(String(decoding: message.body, as: UTF8.self) == "Not Found")

		let urlResponse = try #require(message.urlResponse as? HTTPURLResponse)

		#expect(urlResponse.url == URL(string: "https://example.com/test"))
		#expect(urlResponse.statusCode == 404)
		#expect(urlResponse.value(forHTTPHeaderField: "Content-Type") == "text/plain")
		#expect(urlResponse.value(forHTTPHeaderField: ":status") == "404")
	}

	@Test("Decode throws when URL is missing")
	func testDecodeThrowsForMissingURL() {
		let data = Data("""
			{
				"status": 200,
				"headers": "Content-Type: text/html",
				"body": "OK"
			}
			""".utf8)

		#expect(
			performing: {
				try JSONDecoder().decode(Message.self, from: data)
			},
			throws: { error in
				if case let .keyNotFound(key, _) = error as? DecodingError, case .url = key as? Message.CodingKeys {
					true
				}
				else {
					false
				}
			}
		)
	}

	@Test("Decode throws when status is missing")
	func testDecodeThrowsForMissingStatus() {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"headers": "Content-Type: text/html",
				"body": "OK"
			}
			""".utf8)

		#expect(
			performing: {
				try JSONDecoder().decode(Message.self, from: data)
			},
			throws: { error in
				if case let .keyNotFound(key, _) = error as? DecodingError, case .status = key as? Message.CodingKeys {
					true
				}
				else {
					false
				}
			}
		)
	}

	@Test("Decode throws when headers are missing")
	func testDecodeThrowsForMissingHeaders() {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"status": 200,
				"body": "OK"
			}
			""".utf8)

		#expect(
			performing: {
				try JSONDecoder().decode(Message.self, from: data)
			},
			throws: { error in
				if case let .keyNotFound(key, _) = error as? DecodingError, case .headers = key as? Message.CodingKeys {
					true
				}
				else {
					false
				}
			}
		)
	}

	@Test("Decode throws when body is missing")
	func testDecodeThrowsForMissingBody() {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"status": 200,
				"headers": "Content-Type: text/html"
			}
			""".utf8)

		#expect(
			performing: {
				try JSONDecoder().decode(Message.self, from: data)
			},
			throws: { error in
				if case let .keyNotFound(key, _) = error as? DecodingError, case .body = key as? Message.CodingKeys {
					true
				}
				else {
					false
				}
			}
		)
	}

	@Test("Decode ignores malformed headers")
	func testDecodeIgnoresMalformedHeaders() throws {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"status": 200,
				"headers": "Content-Type: text/html\\r\\nbadheader\\r\\nContent-Length: 42",
				"body": "Hello world!"
			}
			""".utf8)

		let message = try JSONDecoder().decode(Message.self, from: data)

		#expect(message.url == URL(string: "https://example.com/test"))
		#expect(message.status == 200)
		#expect(message.version == "HTTP/1.1")
		#expect(message.headers.count == 2)
		#expect(message.headers["Content-Type"] == "text/html")
		#expect(message.headers["Content-Length"] == "42")
		#expect(message.headers["badheader"] == nil)
		#expect(String(decoding: message.body, as: UTF8.self) == "Hello world!")

		let urlResponse = try #require(message.urlResponse as? HTTPURLResponse)

		#expect(urlResponse.url == URL(string: "https://example.com/test"))
		#expect(urlResponse.statusCode == 200)
		#expect(urlResponse.value(forHTTPHeaderField: "Content-Type") == "text/html")
		#expect(urlResponse.value(forHTTPHeaderField: "Content-Length") == "42")
		#expect(urlResponse.value(forHTTPHeaderField: "badheader") == nil)
	}

	@Test("Decode empty body")
	func testDecodeEmptyBody() throws {
		let data = Data("""
			{
				"url": "https://example.com/test",
				"status": 200,
				"headers": "Content-Type: text/html",
				"body": ""
			}
			""".utf8)

		let message = try JSONDecoder().decode(Message.self, from: data)

		#expect(message.url == URL(string: "https://example.com/test"))
		#expect(message.status == 200)
		#expect(message.version == "HTTP/1.1")
		#expect(message.headers.count == 1)
		#expect(message.headers["Content-Type"] == "text/html")
		#expect(message.body.isEmpty)

		let urlResponse = try #require(message.urlResponse as? HTTPURLResponse)

		#expect(urlResponse.url == URL(string: "https://example.com/test"))
		#expect(urlResponse.statusCode == 200)
		#expect(urlResponse.value(forHTTPHeaderField: "Content-Type") == "text/html")
	}

}
