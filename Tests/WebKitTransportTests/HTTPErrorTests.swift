import Testing
import WebKit
@testable import WebKitTransport

@Suite struct HTTPErrorTests {

	@Test("Init")
	func initialisation() {
		let four_oh_one = HTTPError(statusCode: 401)
		#expect(four_oh_one.statusCode == 401)

		let four_oh_two = HTTPError(statusCode: 402)
		#expect(four_oh_two.statusCode == 402)

		let four_oh_three = HTTPError(statusCode: 403)
		#expect(four_oh_three.statusCode == 403)

		let four_oh_four = HTTPError(statusCode: 404)
		#expect(four_oh_four.statusCode == 404)

		let four_oh_five = HTTPError(statusCode: 405)
		#expect(four_oh_five.statusCode == 405)

		let five_oh_one = HTTPError(statusCode: 501)
		#expect(five_oh_one.statusCode == 501)

		let five_oh_two = HTTPError(statusCode: 502)
		#expect(five_oh_two.statusCode == 502)

		let five_oh_three = HTTPError(statusCode: 503)
		#expect(five_oh_three.statusCode == 503)

		let five_oh_four = HTTPError(statusCode: 504)
		#expect(five_oh_four.statusCode == 504)

		let five_oh_five = HTTPError(statusCode: 505)
		#expect(five_oh_five.statusCode == 505)
	}

	@Test("CustomNSError conformance")
	func asCustomNSError() {
		let four_oh_one = HTTPError(statusCode: 401) as NSError
		#expect(four_oh_one.code == 401)
		#expect(four_oh_one.domain == "WebKitTransport.HTTPError")

		let four_oh_two = HTTPError(statusCode: 402) as NSError
		#expect(four_oh_two.code == 402)
		#expect(four_oh_two.domain == "WebKitTransport.HTTPError")

		let four_oh_three = HTTPError(statusCode: 403) as NSError
		#expect(four_oh_three.code == 403)
		#expect(four_oh_three.domain == "WebKitTransport.HTTPError")

		let four_oh_four = HTTPError(statusCode: 404) as NSError
		#expect(four_oh_four.code == 404)
		#expect(four_oh_four.domain == "WebKitTransport.HTTPError")

		let four_oh_five = HTTPError(statusCode: 405) as NSError
		#expect(four_oh_five.code == 405)
		#expect(four_oh_five.domain == "WebKitTransport.HTTPError")

		let five_oh_one = HTTPError(statusCode: 501) as NSError
		#expect(five_oh_one.code == 501)
		#expect(five_oh_one.domain == "WebKitTransport.HTTPError")

		let five_oh_two = HTTPError(statusCode: 502) as NSError
		#expect(five_oh_two.code == 502)
		#expect(five_oh_two.domain == "WebKitTransport.HTTPError")

		let five_oh_three = HTTPError(statusCode: 503) as NSError
		#expect(five_oh_three.code == 503)
		#expect(five_oh_three.domain == "WebKitTransport.HTTPError")

		let five_oh_four = HTTPError(statusCode: 504) as NSError
		#expect(five_oh_four.code == 504)
		#expect(five_oh_four.domain == "WebKitTransport.HTTPError")

		let five_oh_five = HTTPError(statusCode: 505) as NSError
		#expect(five_oh_five.code == 505)
		#expect(five_oh_five.domain == "WebKitTransport.HTTPError")
	}

	@Test("Informational status (1xx)")
	func fromURLResponseNilForInformational() {
		for statusCode in 100...199 {
			let response = HTTPURLResponse(
				url: URL(string: "https://example.com")!,
				statusCode: statusCode,
				httpVersion: "HTTP/1.1",
				headerFields: nil
			)!

			#expect(response.httpError == nil)
		}
	}

	@Test("Success status (2xx)")
	func fromURLResponseNilForSuccess() {
		for statusCode in 200...299 {
			let response = HTTPURLResponse(
				url: URL(string: "https://example.com")!,
				statusCode: statusCode,
				httpVersion: "HTTP/1.1",
				headerFields: nil
			)!

			#expect(response.httpError == nil)
		}
	}

	@Test("Redirection status (3xx)")
	func fromURLResponseNilForRedirection() {
		for statusCode in 300...399 {
			let response = HTTPURLResponse(
				url: URL(string: "https://example.com")!,
				statusCode: statusCode,
				httpVersion: "HTTP/1.1",
				headerFields: nil
			)!

			#expect(response.httpError == nil)
		}
	}

	@Test("Client error status (4xx)")
	func fromURLResponseReturnedForClientError() throws {
		for statusCode in 400...499 {
			let response = HTTPURLResponse(
				url: URL(string: "https://example.com")!,
				statusCode: statusCode,
				httpVersion: "HTTP/1.1",
				headerFields: nil
			)!

			let error = try #require(response.httpError)
			#expect(error.statusCode == statusCode)
		}
	}

	@Test("Server error status (5xx)")
	func fromURLResponseReturnedForServerError() throws {
		for statusCode in 500...599 {
			let response = HTTPURLResponse(
				url: URL(string: "https://example.com")!,
				statusCode: statusCode,
				httpVersion: "HTTP/1.1",
				headerFields: nil
			)!

			let error = try #require(response.httpError)
			#expect(error.statusCode == statusCode)
		}
	}

}
