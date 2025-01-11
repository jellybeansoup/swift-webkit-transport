import UIKit
import WebKit

@MainActor
class ViewController: UIViewController {

	/// The window that the `WebViewController` appears in.
	lazy var window: UIWindow = {
		let window = UIWindow()
		window.alpha = 0
		window.backgroundColor = UIColor.clear
		window.rootViewController = self
		window.isUserInteractionEnabled = false
		return window
	}()

	// MARK: Managing the web view

	/// The underlying web view.
	/// - Note: This is loaded lazily to avoid potential issues with it being initialised on a background thread.
	lazy var webView: WKWebView = loadWebView()

	private func loadWebView() -> WKWebView {
		let webView = WKWebView()
		webView.isUserInteractionEnabled = false

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

		window.frame = CGRect(x: UIScreen.main.bounds.maxX, y: UIScreen.main.bounds.maxY, width: 320.0, height: 568.0 * 3)
		window.isHidden = false

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

		window.isHidden = true

		webView.stopLoading()
		webView.load(
			Data(),
			mimeType: "text/plain",
			characterEncodingName: "UTF-8",
			baseURL: URL(fileURLWithPath: "/")
		)
	}

}
