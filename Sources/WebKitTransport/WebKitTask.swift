import Foundation
import WebKit

public struct WebKitTask: AsyncSequence, Sendable {

	public typealias Payload = (data: Data, response: URLResponse)

	private let underlyingStream: AsyncStream<Payload>

	private let underlyingTask: Task<Void, Never>?

	private init(
		stream: AsyncStream<Payload>,
		task: Task<Void, Never>? = nil
	) {
		self.underlyingStream = stream
		self.underlyingTask = task
	}

	private init(request: URLRequest, session: URLSession, timeout: TimeInterval) async throws {
		let payload: (data: Data, response: URLResponse) = try await session.data(for: request)

		if let httpError = payload.response.httpError {
			throw httpError
		}
		else if !payload.data.isEmpty, payload.response.mimeType == "text/html" {
			self.init(data: payload.data, response: payload.1, timeout: timeout)
		}
		else {
			self.init(stream: .init {
				$0.yield(payload)
				$0.finish()
			})
		}
	}

	private init(data: Data, response: URLResponse, timeout: TimeInterval) {
		var continuation: AsyncStream<Payload>.Continuation!
		self.underlyingStream = .init { continuation = $0 }
		self.underlyingTask = Task.detached { [continuation] in
			let viewController = await ViewController()
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

	private static func stopLoading(_ viewController: ViewController, after seconds: TimeInterval) -> Task<Void, Never> {
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

	public static let defaultTimeout: TimeInterval = 1.5

	public static func load(_ url: URL, using session: URLSession = .shared, timeout: TimeInterval = Self.defaultTimeout) async throws -> Self {
		try await Self.init(request: URLRequest(url: url), session: session, timeout: timeout)
	}

	public static func load(_ request: URLRequest, using session: URLSession = .shared, timeout: TimeInterval = Self.defaultTimeout) async throws -> Self {
		try await Self.init(request: request, session: session, timeout: timeout)
	}

	public static func load(data: Data, response: URLResponse, timeout: TimeInterval = Self.defaultTimeout) -> Self {
		Self.init(data: data, response: response, timeout: timeout)
	}

	public func cancel() {
		underlyingTask?.cancel()
	}

	// MARK: AsyncSequence

	public typealias AsyncIterator = AsyncStream<Payload>.AsyncIterator

	public typealias Element = Payload

	public func makeAsyncIterator() -> AsyncIterator {
		underlyingStream.makeAsyncIterator()
	}

}
