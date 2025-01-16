import Foundation
import Testing
@testable import WebKitTransport

@Suite struct WebKitTaskTests {

	private class MockViewController: ViewControllerProtocol {

		var loadParameters: (data: Data, response: URLResponse)?

		var stopLoadingWasCalled = false

		func load(data: Data, response: URLResponse) -> AsyncStream<WebKitTransport.WebKitTask.Payload> {
			self.loadParameters = (data, response)
			return AsyncStream {
				$0.yield((data, response))
				$0.finish()
			}
		}
		
		func stopLoading() {
			self.stopLoadingWasCalled = true
		}

	}

	private class MockURLSession: URLSessionProtocol {

		var handler: (_ request: URLRequest) throws -> (Data, URLResponse)

		init(handler: @escaping (_ request: URLRequest) throws -> (Data, URLResponse)) {
			self.handler = handler
		}

		func data(for request: URLRequest) throws -> (Data, URLResponse) {
			try handler(request)
		}

	}

	private enum MockError: Error {
		case mock
	}

	@Test func initWithURLRequest() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let request = URLRequest(url: url)

		let data = Data("<!DOCTYPE html><html><body>Hello, world!</body></html>".utf8)
		let response = try #require(HTTPURLResponse(
			url: url,
			statusCode: 200,
			httpVersion: "HTTP/1.1",
			headerFields: ["Content-Type": "text/html"]
		))

		var capturedRequest: URLRequest?
		let urlSession = MockURLSession { request in
			capturedRequest = request
			return (data, response)
		}

		let viewController = MockViewController()

		let task = try await WebKitTask(
			request: request,
			session: urlSession,
			timeout: 10,
			viewControllerProvider: { viewController }
		)

		#expect(capturedRequest == request)

		let payload = await confirmation { confirmation in
			var captured: WebKitTask.Payload?
			for await payload in task {
				captured = payload
				confirmation.confirm()
			}
			return captured
		}

		#expect(payload?.data == data)
		#expect(payload?.response == response)

		let loadParameters = try #require(await viewController.loadParameters)

		#expect(loadParameters.data == data)
		#expect(loadParameters.response == response)
	}

	@Test func initWithURLRequestThrowsError() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let request = URLRequest(url: url)

		var capturedRequest: URLRequest?
		let urlSession = MockURLSession { request in
			capturedRequest = request
			throw MockError.mock
		}

		let viewController = MockViewController()

		await #expect(throws: MockError.self) {
			_ = try await WebKitTask(
				request: request,
				session: urlSession,
				timeout: 10,
				viewControllerProvider: { viewController }
			)
		}

		#expect(capturedRequest == request)
	}

	@Test func initWithURLRequestReturningHTTPError() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let request = URLRequest(url: url)

		let data = Data("<!DOCTYPE html><html><body>Hello, world!</body></html>".utf8)
		let response = try #require(HTTPURLResponse(
			url: url,
			statusCode: 500,
			httpVersion: "HTTP/1.1",
			headerFields: ["Content-Type": "text/html"]
		))

		var capturedRequest: URLRequest?
		let urlSession = MockURLSession { request in
			capturedRequest = request
			return (data, response)
		}

		let viewController = MockViewController()

		await #expect(throws: HTTPError.self) {
			_ = try await WebKitTask(
				request: request,
				session: urlSession,
				timeout: 10,
				viewControllerProvider: { viewController }
			)
		}

		#expect(capturedRequest == request)
	}

	@Test func initWithURLRequestReturningEmptyData() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let request = URLRequest(url: url)

		let data = Data()
		let response = HTTPURLResponse(
			url: url,
			mimeType: "text/html",
			expectedContentLength: -1,
			textEncodingName: "utf-8"
		)

		var capturedRequest: URLRequest?
		let urlSession = MockURLSession { request in
			capturedRequest = request
			return (data, response)
		}

		let viewController = MockViewController()

		let task = try await WebKitTask(
			request: request,
			session: urlSession,
			timeout: 10,
			viewControllerProvider: { viewController }
		)

		#expect(capturedRequest == request, "The URLSession is called with the correct URLRequest")

		#expect(task.underlyingStream != nil)
		#expect(task.underlyingTask == nil)

		let payload = await confirmation { confirmation in
			var captured: WebKitTask.Payload?
			for await payload in task {
				captured = payload
				confirmation.confirm()
			}
			return captured
		}

		#expect(payload?.data == data)
		#expect(payload?.response == response)

		#expect(await viewController.loadParameters == nil, "The ViewController's load function is never called")
	}

	@Test func initWithData() {

	}

}
