import Testing
import WebKit
@testable import WebKitTransport

@MainActor
@Suite struct MessageHandlerTests {

	private func urlResponse() -> URLResponse {
		.init(
			url: URL(string: "https://example.com")!,
			mimeType: "text/html",
			expectedContentLength: 123,
			textEncodingName: "utf-8"
		)
	}

	@Test("Init adds message handlers and user scripts")
	func initialisation() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()

		// We have to initialise the MessageHandler
		// NOTE: message handlers and user scripts are not removed on deinit.
		_ = MessageHandler(for: userContentController, using: response)

		// Verify the script message handlers were added
		#expect(userContentController.capturedScriptMessageHandlers.count == 2)
		#expect(userContentController.capturedScriptMessageHandlers["document"] != nil)
		#expect(userContentController.capturedScriptMessageHandlers["xhr"] != nil)

		// Verify the user script was added
		#expect(userContentController.capturedUserScripts.count == 1)
		#expect(userContentController.capturedUserScripts.first?.source == MessageHandler.javascript)
	}

	@Test("Stream yields payload when `document` message is received")
	func documentMessageYieldsPayload() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in handler.messages {
				return payload
			}

			return nil
		}

		let body = "HTML content"
		let message = MockScriptMessage(name: "document", body: body)
		handler.userContentController(userContentController, didReceive: message)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response.url == response.url)
	}

	@Test("Stream yields payload when `xhr` message is received")
	func xhrMessageYieldsPayload() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in handler.messages {
				return payload
			}

			return nil
		}

		let body = """
			{
				"url": "https://example.com",
				"status": 200,
				"headers": "Content-Type: text/plain",
				"body": "XHR Body"
			}
			"""
		let message = MockScriptMessage(name: "xhr", body: body)
		handler.userContentController(userContentController, didReceive: message)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("XHR Body".utf8))
		#expect(payload.response.url?.absoluteString == "https://example.com")
		#expect((payload.response as? HTTPURLResponse)?.statusCode == 200)
		#expect((payload.response as? HTTPURLResponse)?.mimeType == "text/plain")
	}

	@Test("Stream ignores invalid `xhr` messages")
	func ignoresInvalidXHRMessage() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in handler.messages {
				return payload
			}

			return nil
		}

		let message = MockScriptMessage(name: "xhr", body: "{}")
		handler.userContentController(userContentController, didReceive: message)

		// Sending a valid message forces the stream to emit
		let documentMessage = MockScriptMessage(name: "document", body: "HTML content")
		handler.userContentController(userContentController, didReceive: documentMessage)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response.url == response.url)
	}

	@Test("Stream ignores unknown messages")
	func ignoresUnknownMessages() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in handler.messages {
				return payload
			}

			return nil
		}

		let invalidMessage = MockScriptMessage(name: "INVALID", body: "")
		handler.userContentController(userContentController, didReceive: invalidMessage)

		// Sending a valid message forces the stream to emit
		let documentMessage = MockScriptMessage(name: "document", body: "HTML content")
		handler.userContentController(userContentController, didReceive: documentMessage)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response.url == response.url)
	}

	@Test("Stream ignores unknown messages")
	func ignoresEmptyMessages() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in handler.messages {
				return payload
			}

			return nil
		}

		let invalidMessage = MockScriptMessage(name: "document", body: 123)
		handler.userContentController(userContentController, didReceive: invalidMessage)

		// Sending a valid message forces the stream to emit
		let documentMessage = MockScriptMessage(name: "document", body: "HTML content")
		handler.userContentController(userContentController, didReceive: documentMessage)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response.url == response.url)
	}

	@Test("Finish removes message handlers and user scripts")
	func finish() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		handler.finish()

		#expect(userContentController.capturedScriptMessageHandlers.isEmpty)
		#expect(userContentController.capturedUserScripts.isEmpty)

		let payload = try await withTimeout(10) {
			var iterator = handler.messages.makeAsyncIterator()
			return await iterator.next()
		}

		#expect(payload == nil)
	}

}
