#if canImport(AppKit)
import AppKit
import WebKit

final class ViewController: NSViewController {

	/// The window that the `WebViewController` appears in.
	lazy var window: NSWindow = {
		let window = NSWindow()
		window.alphaValue = 0
		window.backgroundColor = NSColor.clear
		window.contentViewController = self
		window.isMovable = false
		window.ignoresMouseEvents = true
		return window
	}()

	// MARK: Managing the web view

	/// The underlying web view.
	/// - Note: This is loaded lazily to avoid potential issues with it being initialised on a background thread.
	lazy var webView: WKWebView = loadWebView()

	private func loadWebView() -> WKWebView {
		let webView = WKWebView()

		webView.configuration.applicationNameForUserAgent = "GIFwrapped"
		webView.configuration.mediaTypesRequiringUserActionForPlayback = .all
		webView.configuration.suppressesIncrementalRendering = true
		webView.configuration.websiteDataStore = .nonPersistent()

		return webView
	}

	// MARK: View controller overrides

	override func loadView() {
		self.view = webView
	}

	// MARK: Loading content

	private var messageHandler: MessageHandler!

	func load(data: Data, response: URLResponse) -> AsyncStream<WebKitTask.Payload> {
		messageHandler = MessageHandler(
			for: webView.configuration.userContentController,
			using: response
		)

		window.setFrame(NSRect(x: 0, y: 0, width: 320.0, height: 568.0 * 3), display: true, animate: false)
		webView.load(
			data,
			mimeType: response.mimeType ?? "text/html",
			characterEncodingName: response.textEncodingName ?? "UTF-8",
			baseURL: response.url ?? URL(fileURLWithPath: "/")
		)

		return messageHandler!.messages
	}

	func stopLoading() {
		messageHandler?.finish()
		messageHandler = nil

		webView.stopLoading()
		webView.load(
			Data(),
			mimeType: "text/plain",
			characterEncodingName: "UTF-8",
			baseURL: URL(fileURLWithPath: "/")
		)
	}

}
#endif
