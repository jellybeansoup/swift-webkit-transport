import Foundation
import Testing
@testable import WebKitTransport

@Suite struct WebKitTaskTests {

	private class MockViewController: ViewControllerProtocol {

		var shouldYield: Bool

		var loadParameters: (data: Data, response: URLResponse)?

		var stopLoadingWasCalled = false

		private var continuation: AsyncStream<WebKitTask.Payload>.Continuation?

		init(
			shouldYield: Bool = true
		) {
			self.shouldYield = shouldYield
		}

		func load(data: Data, response: URLResponse) -> AsyncStream<WebKitTask.Payload> {
			self.loadParameters = (data, response)
			return AsyncStream {
				self.continuation = $0

				if shouldYield {
					$0.yield((data, response))
					$0.finish()
				}
			}
		}

		func stopLoading() {
			self.stopLoadingWasCalled = true
			self.continuation?.finish()
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

	@Test func initWithStreamAndTask() async throws {
		let data = Data("<!DOCTYPE html><html><body>Hello world!</body></html>".utf8)
		let response = try #require(HTTPURLResponse(
			url: URL(fileURLWithPath: "/"),
			statusCode: 200,
			httpVersion: "HTTP/1.1",
			headerFields: ["Content-Type": "text/html"]
		))

		var continuation: AsyncStream<WebKitTask.Payload>.Continuation!
		let underlyingStream = AsyncStream<WebKitTask.Payload> { continuation = $0 }
		let underlyingTask = Task { [continuation] in
			continuation?.yield((data, response))
			continuation?.finish()
		}

		let task = WebKitTask(stream: underlyingStream, task: underlyingTask)

		#expect(task.underlyingStream != nil)
		#expect(task.underlyingTask == underlyingTask)

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
	}

	@Test func initWithURLRequest() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let request = URLRequest(url: url)

		let data = Data("<!DOCTYPE html><html><body>Hello world!</body></html>".utf8)
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

		let viewController = await MockViewController()

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

		let viewController = await MockViewController()

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

		let data = Data("<!DOCTYPE html><html><body>Hello world!</body></html>".utf8)
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

		let viewController = await MockViewController()

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

		let viewController = await MockViewController()

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

	@Test func initWithURLRequestTimesOut() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let request = URLRequest(url: url)

		let data = Data("<!DOCTYPE html><html><body>Hello world!</body></html>".utf8)
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

		let viewController = await MockViewController(shouldYield: false)

		let task = try await WebKitTask(
			request: request,
			session: urlSession,
			timeout: 0.1,
			viewControllerProvider: { viewController }
		)

		#expect(capturedRequest == request, "The URLSession is called with the correct URLRequest")

		let payload = await confirmation(expectedCount: 0) { confirmation in
			var captured: WebKitTask.Payload?
			for await payload in task {
				captured = payload
				confirmation.confirm()
			}
			return captured
		}

		#expect(payload == nil)

		let loadParameters = try #require(await viewController.loadParameters)
		#expect(loadParameters.data == data)
		#expect(loadParameters.response == response)
	}

	@Test func initWithData() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let data = Data("<!DOCTYPE html><html><body>Hello world!</body></html>".utf8)
		let response = try #require(HTTPURLResponse(
			url: url,
			statusCode: 200,
			httpVersion: "HTTP/1.1",
			headerFields: ["Content-Type": "text/html"]
		))

		let viewController = await MockViewController()

		let task = WebKitTask(
			data: data,
			response: response,
			timeout: 10,
			viewControllerProvider: { viewController }
		)

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

	@Test func initWithDataTimesOut() async throws {
		let url = try #require(URL(string: "https://example.com"))
		let data = Data("<!DOCTYPE html><html><body>Hello world!</body></html>".utf8)
		let response = try #require(HTTPURLResponse(
			url: url,
			statusCode: 200,
			httpVersion: "HTTP/1.1",
			headerFields: ["Content-Type": "text/html"]
		))

		let viewController = await MockViewController(shouldYield: false)

		let task = WebKitTask(
			data: data,
			response: response,
			timeout: 0.1,
			viewControllerProvider: { viewController }
		)

		let payload = await confirmation(expectedCount: 0) { confirmation in
			var captured: WebKitTask.Payload?
			for await payload in task {
				captured = payload
				confirmation.confirm()
			}
			return captured
		}

		#expect(payload == nil)

		let loadParameters = try #require(await viewController.loadParameters)
		#expect(loadParameters.data == data)
		#expect(loadParameters.response == response)

		#expect(await viewController.stopLoadingWasCalled == true)
	}

	@Test func stopLoading() async throws {
		let viewController = await MockViewController()

		// Cancelling the task DOES NOT stop loading

		let taskForCancelling = WebKitTask.stopLoading(viewController, after: 0.5)
		taskForCancelling.cancel()

		await taskForCancelling.value

		#expect(taskForCancelling.isCancelled)
		#expect(await viewController.stopLoadingWasCalled == false)

		// Allowing the task to complete DOES stop loading

		let taskForCompleting = WebKitTask.stopLoading(viewController, after: 0.5)

		await taskForCompleting.value

		#expect(taskForCompleting.isCancelled == false)
		#expect(await viewController.stopLoadingWasCalled == true)
	}

	@Test func cancel() async throws {
		var continuation: AsyncStream<WebKitTask.Payload>.Continuation!
		let underlyingStream = AsyncStream<WebKitTask.Payload> { continuation = $0 }
		let underlyingTask = Task { [continuation] in
			await #expect(throws: Error.self) { try await Task.sleep(nanoseconds: 1 * 1_000_000_000) }
			continuation?.finish()
		}

		let task = WebKitTask(stream: underlyingStream, task: underlyingTask)

		#expect(task.underlyingStream != nil)
		#expect(task.underlyingTask == underlyingTask)

		task.cancel()

		#expect(underlyingTask.isCancelled)

		let payload = await confirmation(expectedCount: 0) { confirmation in
			var captured: WebKitTask.Payload?
			for await payload in task {
				captured = payload
				confirmation.confirm()
			}
			return captured
		}

		#expect(payload == nil)
	}

}
