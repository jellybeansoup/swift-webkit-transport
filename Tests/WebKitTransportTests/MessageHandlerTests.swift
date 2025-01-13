import Testing
import WebKit
@testable import WebKitTransport

@MainActor
@Suite struct MessageHandlerTests {

	final class MockUserContentController: WKUserContentController {

		private(set) var capturedScriptMessageHandlers: [String: WKScriptMessageHandler] = [:]
		private(set) var capturedUserScripts: [WKUserScript] = []

		override func add(_ scriptMessageHandler: WKScriptMessageHandler, name: String) {
			capturedScriptMessageHandlers[name] = scriptMessageHandler
		}

		override func removeAllScriptMessageHandlers() {
			capturedScriptMessageHandlers.removeAll()
		}

		override func addUserScript(_ userScript: WKUserScript) {
			capturedUserScripts.append(userScript)
		}

		override func removeAllUserScripts() {
			capturedUserScripts.removeAll()
		}

	}

	final class FakeWKScriptMessage: WKScriptMessage {
		private let _name: String
		private let _body: Any

		init(name: String, body: Any) {
			self._name = name
			self._body = body
			super.init()
		}

		override var name: String {
			return _name
		}

		override var body: Any {
			return _body
		}
	}

	private func urlResponse() -> URLResponse {
		.init(
			url: URL(string: "https://example.com")!,
			mimeType: "text/html",
			expectedContentLength: 123,
			textEncodingName: "utf-8"
		)
	}

	@Test(.timeLimit(.minutes(1)))
	func testInitializationAddsScriptsAndMessageHandlers() async throws {
		let userContentController = MockUserContentController()
		let response = urlResponse()

		// We have to initialise the MessageHandler
		_ = MessageHandler(for: userContentController, using: response)

		// Verify the script message handlers were added
		#expect(userContentController.capturedScriptMessageHandlers.count == 2)
		#expect(userContentController.capturedScriptMessageHandlers["document"] != nil)
		#expect(userContentController.capturedScriptMessageHandlers["xhr"] != nil)

		// Verify the user script was added
		#expect(userContentController.capturedUserScripts.count == 1)
		#expect(userContentController.capturedUserScripts.first?.source == MessageHandler.javascript)
	}

	@Test func didReceiveDocumentMessageYieldsPayload() async throws {
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
		let message = FakeWKScriptMessage(name: "document", body: body)
		handler.userContentController(userContentController, didReceive: message)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response.url == response.url)
	}

	@Test func didReceiveXHRMessageYieldsPayload() async throws {
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
		let message = FakeWKScriptMessage(name: "xhr", body: body)
		handler.userContentController(userContentController, didReceive: message)

		let payload = try #require(await task.value)

		#expect(payload.data == Data("XHR Body".utf8))
		#expect(payload.response.url?.absoluteString == "https://example.com")
		#expect((payload.response as? HTTPURLResponse)?.statusCode == 200)
		#expect((payload.response as? HTTPURLResponse)?.mimeType == "text/plain")
	}

	@Test(.timeLimit(.minutes(1)))
	func finishRemovesAllHandlersAndScripts_stopsYielding() async {
		let userContentController = MockUserContentController()
		let response = urlResponse()
		let handler = MessageHandler(for: userContentController, using: response)

		handler.finish()

		#expect(userContentController.capturedScriptMessageHandlers.isEmpty)
		#expect(userContentController.capturedUserScripts.isEmpty)

		await confirmation(expectedCount: 0) { confirmation in
			for await _ in handler.messages {
				confirmation.confirm()
			}
		}
	}

}
