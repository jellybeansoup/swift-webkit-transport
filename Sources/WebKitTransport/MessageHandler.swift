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
					logger.error("Error handling '\(message.name)' message: \(body): \(error)")
				}

			default:
				logger.notice("Received unexpected message '\(message.name)' message: \(body)")
			}
	}

	// MARK: Javascript

	static let javascript: String = """
		var xhrInFlight = 0

		function xhrDidFinish() {
			xhrInFlight -= 1;
		}

		var open = XMLHttpRequest.prototype.open;
		XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
			xhrInFlight += 1;

			this.addEventListener("load", function() {
				var body = this.responseText.trim();

				if (body.length == 0) { return } // Nothing to parse if the body is empty

				webkit.messageHandlers.xhr.postMessage(JSON.stringify({
					"url": this.responseURL,
					"status": this.status,
					"headers": this.getAllResponseHeaders().trim(),
					"body": body
				}));
			});

			this.addEventListener("load", xhrDidFinish);
			this.addEventListener("error", xhrDidFinish);
			this.addEventListener("abort", xhrDidFinish);

			open.apply(this, arguments);
		};

		var previousHTML = ""
		function callback() {
			if (xhrInFlight > 0) { return }
			if (document.readyState !== "complete") { return }
			if (document.querySelector("meta[http-equiv='refresh']") !== null) { return }
			let html = window.document.documentElement.outerHTML;
			if (html === previousHTML) { return }
			clearInterval(checkDocumentLoaded);
			webkit.messageHandlers.document.postMessage(html);
		}

		var observer = new MutationObserver(callback);

		observer.observe(window.document.documentElement, {
			childList: true,
			attributes: true,
			subtree: true
		});

		var checkDocumentLoaded = setInterval(callback, 100);
		"""

}
