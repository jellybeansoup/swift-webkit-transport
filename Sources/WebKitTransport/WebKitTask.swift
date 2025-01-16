import Foundation
import WebKit

/// Represents a task that loads and processes web content using WebKit.
///
/// `WebKitTask` provides an asynchronous sequence interface for processing web content,
/// with the ability to load data, handle timeouts, and manage the loading lifecycle.
public struct WebKitTask: AsyncSequence, Sendable {

	public typealias Payload = (data: Data, response: URLResponse)

	let underlyingStream: AsyncStream<Payload>

	let underlyingTask: Task<Void, Never>?

	init(
		stream: AsyncStream<Payload>,
		task: Task<Void, Never>? = nil
	) {
		self.underlyingStream = stream
		self.underlyingTask = task
	}

	init(
		request: URLRequest,
		session: URLSessionProtocol,
		timeout: TimeInterval,
		viewControllerProvider: @MainActor @escaping @Sendable () -> ViewControllerProtocol
	) async throws {
		let payload: (data: Data, response: URLResponse) = try await session.data(for: request)

		if let httpError = payload.response.httpError {
			throw httpError
		}
		else if !payload.data.isEmpty, payload.response.mimeType == "text/html" {
			self.init(data: payload.data, response: payload.response, timeout: timeout, viewControllerProvider: viewControllerProvider)
		}
		else {
			self.init(stream: .init {
				$0.yield(payload)
				$0.finish()
			})
		}
	}

	init(
		data: Data,
		response: URLResponse,
		timeout: TimeInterval,
		viewControllerProvider: @MainActor @escaping @Sendable () -> ViewControllerProtocol
	) {
		var continuation: AsyncStream<Payload>.Continuation!
		self.underlyingStream = .init { continuation = $0 }
		self.underlyingTask = Task.detached { [continuation] in
			let viewController = await viewControllerProvider()
			let stream = await viewController.load(data: data, response: response)

			var timeoutTask: Task<Void, Never>?

			for await payload in stream {
				timeoutTask?.cancel()

				continuation?.yield(payload)

				timeoutTask = Self.stopLoading(viewController, after: timeout)
			}

			continuation?.finish()
		}
	}

	private static func stopLoading(_ viewController: ViewControllerProtocol, after seconds: TimeInterval) -> Task<Void, Never> {
		Task.detached { [weak viewController] in
			if #available(iOS 16.0, macOS 13.0, *) {
				try? await Task.sleep(for: .seconds(seconds))
			}
			else {
				let nanoseconds = UInt64(seconds * 1_000_000_000)
				try? await Task.sleep(nanoseconds: nanoseconds)
			}

			await viewController?.stopLoading()
		}
	}

	// MARK: Public interface

	/// The default timeout interval for loading web content, in seconds.
	public static let defaultTimeout: TimeInterval = 1.5

	/// Loads web content from the specified ``URL``
	///
	/// This method loads the initial page content using the given `session`. The response is then loaded
	/// into a ``WKWebView`` which allows the page's JavaScript to run. Additional responses from in-page
	/// XMLHttpRequests are captured and emitted, as follows:
	/// ```swift
	/// let url = URL(string: "https://example.com")!
	/// for try await (data, response) in WebKitTask.load(url) {
	///	    // Process incoming data and response
	///	    // The first response will always be the response from the underlying URLSession call.
	/// }
	/// ```
	/// - Parameters:
	///   - url: The URL to load.
	///   - session: The `URLSession` instance to use for the request. Defaults to `.shared`.
	///   - timeout: The timeout interval for the task, in seconds. Defaults to `defaultTimeout`.
	/// - Returns: A `WebKitTask` instance that streams the loaded content.
	/// - Throws: An error if the request fails or if the response indicates an HTTP error.
	public static func load(_ url: URL, using session: URLSession = .shared, timeout: TimeInterval = Self.defaultTimeout) async throws -> Self {
		try await Self.init(request: URLRequest(url: url), session: session, timeout: timeout) {
			ViewController()
		}
	}

	/// Loads web content from the specified ``URLRequest``.
	///
	/// This method loads the initial page content using the given `session`. The response is then loaded
	/// into a ``WKWebView`` which allows the page's JavaScript to run. Additional responses from in-page
	/// XMLHttpRequests are captured and emitted, as follows:
	/// ```swift
	/// let request = URLRequest(url: URL(string: "https://example.com")!)
	/// for try await (data, response) in WebKitTask.load(request) {
	///	    // Process incoming data and response
	///	    // The first response will always be the response from the underlying URLSession call.
	/// }
	/// ```
	/// - Parameters:
	///   - request: The `URLRequest` to load.
	///   - session: The `URLSession` instance to use for the request. Defaults to `.shared`.
	///   - timeout: The timeout interval for the task, in seconds. Defaults to `defaultTimeout`.
	/// - Returns: A `WebKitTask` instance that streams the loaded content.
	/// - Throws: An error if the request fails or if the response indicates an HTTP error.
	public static func load(_ request: URLRequest, using session: URLSession = .shared, timeout: TimeInterval = Self.defaultTimeout) async throws -> Self {
		try await Self.init(request: request, session: session, timeout: timeout) {
			ViewController()
		}
	}

	/// Loads web content directly from raw data and response objects.
	///
	/// The given data and response is then loaded into a ``WKWebView`` which allows the page's
	/// JavaScript to run. Additional responses from in-page XMLHttpRequests are captured and emitted,
	/// as follows:
	/// ```swift
	/// let inputData = Data(#"<!DOCTYPE html><html>...</html>"#.utf8)
	/// let inputResponse = URLResponse(
	///     url: URL(string: "http//example.com")!,
	///     mimeType: "text/html",
	///     expectedContentLength: inputData.count,
	///     textEncodingName: "UTF-8"
	/// )
	/// for try await (data, response) in WebKitTask.load(data: data, response: response) {
	///	    // Process incoming data and response
	///	    // The first response will always be the provided content.
	/// }
	/// ```
	/// - Parameters:
	///   - data: The raw data of the content.
	///   - response: The `URLResponse` associated with the data.
	///   - timeout: The timeout interval for the task, in seconds. Defaults to `defaultTimeout`.
	/// - Returns: A `WebKitTask` instance that streams the loaded content.
	public static func load(data: Data, response: URLResponse, timeout: TimeInterval = Self.defaultTimeout) -> Self {
		Self.init(data: data, response: response, timeout: timeout) {
			ViewController()
		}
	}

	/// Cancels the underlying task, stopping any ongoing processing.
	///
	/// This method can be called to explicitly stop a `WebKitTask` that is no longer needed.
	public func cancel() {
		underlyingTask?.cancel()
	}

	// MARK: AsyncSequence

	/// The iterator type for the asynchronous sequence.
	public typealias AsyncIterator = AsyncStream<Payload>.AsyncIterator

	/// The element type emitted by the asynchronous sequence.
	public typealias Element = Payload

	/// Creates an asynchronous iterator over the `WebKitTask` sequence.
	///
	/// - Returns: An `AsyncIterator` instance to iterate through the payloads.
	public func makeAsyncIterator() -> AsyncIterator {
		underlyingStream.makeAsyncIterator()
	}

}
