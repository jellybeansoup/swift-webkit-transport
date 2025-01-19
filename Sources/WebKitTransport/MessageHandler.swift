import Foundation
import WebKit
import os.log

final class MessageHandler: NSObject, WKScriptMessageHandler {

	let messages: AsyncStream<WebKitTask.Payload>

	private let documentResponse: URLResponse

	private let userContentController: WKUserContentController

	private let continuation: AsyncStream<WebKitTask.Payload>.Continuation

	let logger = Logger(subsystem: "com.jellystyle.WebKitTransport", category: "MessageHandler")

	init(
		for userContentController: WKUserContentController,
		using documentResponse: URLResponse
	) {
		self.documentResponse = documentResponse
		self.userContentController = userContentController

		var continuation: AsyncStream<WebKitTask.Payload>.Continuation!
		self.messages = .init { continuation = $0 }
		self.continuation = continuation

		super.init()

		userContentController.add(self, name: "document")
		userContentController.add(self, name: "xhr")
		userContentController.addUserScript(WKUserScript(
			source: Self.javascript,
			injectionTime: .atDocumentEnd,
			forMainFrameOnly: false
		))
	}

	func finish() {
		userContentController.removeAllUserScripts()
		userContentController.removeAllScriptMessageHandlers()

		continuation.finish()
	}

	// MARK: WKScriptMessageHandler

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		guard let body = message.body as? String else {
			// NOTE: this enables the capture of empty messages, should they be
			// sent, which makes things easier to debug. It should not be seen
			// in the wild, as the messages that may be received are fixed.
			logger.notice("Received invalid type (\(type(of: message.body))) for message '\(message.name)'.")

			return
		}

		let data = Data(body.utf8)

		switch message.name {
		case "document":
			continuation.yield((data, documentResponse))

		case "xhr":
			do {
				let xhr = try JSONDecoder().decode(Message.self, from: data)

				if let xhrResponse = xhr.urlResponse {
					continuation.yield((xhr.body, xhrResponse))
				}
			}
			catch {
				// NOTE: this error typically represents an unexpected change
				// within this library (either the ``Message`` struct, or the
				// JavaScript that builds it), and should not be thrown.
				logger.error("Error handling '\(message.name)' message: \(body): \(error)")
			}

		default:
			// NOTE: this enables the capture of new messages, should they be
			// added, which makes things easier to debug. It should not be seen
			// in the wild, as the messages that may be received are fixed.
			logger.notice("Received unexpected message '\(message.name)' message: \(body)")
		}
	}

	// MARK: Javascript

	static let javascript: String = {
		let javascript = String(bytes: PackageResources.MessageHandler_js, encoding: .utf8)
		precondition(javascript != nil && javascript?.isEmpty == false, "Cannot decode the source for MessageHandler.js")
		return javascript ?? ""
	}()

}
