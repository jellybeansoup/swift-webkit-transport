import Foundation
import Testing
import WebKit
@testable import WebKitTransport

@MainActor
@Suite struct ViewControllerTests {

	@Test("WKWebView loads with correct configuration")
	func loadWebView() throws {
		let viewController = ViewController()
		let webView = viewController.webView

		#expect(webView.configuration.applicationNameForUserAgent == "WebKitTransport")
		#expect(webView.configuration.mediaTypesRequiringUserActionForPlayback == .all)
		#expect(webView.configuration.suppressesIncrementalRendering == true)
		#expect(webView.configuration.websiteDataStore.isPersistent == false)
	}

	@Test("Loads the given data and HTTPURLResponse into the WKWebView")
	func loadDataAndResponse() async throws {
		let webView = MockWebView()
		let viewController = ViewController()
		viewController.webView = webView

		let data = Data(#"{ "example": true }"#.utf8)
		let mimeType = "application/json"
		let characterEncodingName = "utf-16"
		let baseURL = URL(string: "https://example.com")!
		let response = try #require(
			HTTPURLResponse(
				url: baseURL,
				statusCode: 200,
				httpVersion: "HTTP/2",
				headerFields: [
					"Content-Type": "\(mimeType); charset=\(characterEncodingName)",
				]
			)
		)

		let stream = viewController.load(data: data, response: response)

		// Validate the window position
		#expect(viewController.window.frame.origin.x == -320.0)
		#expect(viewController.window.frame.origin.y == 0.0)
		#expect(viewController.window.frame.size.width == 320.0)
		#expect(viewController.window.frame.size.height == 568.0 * 3)

		// Validate the parameters sent to the webView
		#expect(webView.loadDataParameters?.data == data)
		#expect(webView.loadDataParameters?.mimeType == mimeType)
		#expect(webView.loadDataParameters?.characterEncodingName == characterEncodingName)
		#expect(webView.loadDataParameters?.baseURL == baseURL)

		// Validate that sending the message handler a message yields a payload to the stream
		let messageHandler = try #require(viewController.messageHandler)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in stream {
				return payload
			}

			return nil
		}

		let message = MockScriptMessage(name: "document", body: "HTML content")
		messageHandler.userContentController(.init(), didReceive: message)

		let payload = try #require(await withTimeout(10) { await task.value })

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response == response)
	}

	@Test("Loads the given data and an empty URLResponse into the WKWebView")
	func loadDataAndEmptyResponse() async throws {
		let webView = MockWebView()
		let viewController = ViewController()
		viewController.webView = webView

		let data = Data(#"<!DOCTYPE html><html><body></body></html>""#.utf8)
		let response = try #require(URLResponse())

		let stream = viewController.load(data: data, response: response)

		// Validate the window position
		#expect(viewController.window.frame.origin.x == -320.0)
		#expect(viewController.window.frame.origin.y == 0.0)
		#expect(viewController.window.frame.size.width == 320.0)
		#expect(viewController.window.frame.size.height == 568.0 * 3)

		// Validate the parameters sent to the webView
		#expect(webView.loadDataParameters?.data == data)
		#expect(webView.loadDataParameters?.mimeType == "application/octet-stream")
		#expect(webView.loadDataParameters?.characterEncodingName == "UTF-8")
		#expect(webView.loadDataParameters?.baseURL == URL(fileURLWithPath: "/"))

		// Validate that sending the message handler a message yields a payload to the stream
		let messageHandler = try #require(viewController.messageHandler)

		let task = Task<WebKitTask.Payload?, Never> {
			for await payload in stream {
				return payload
			}

			return nil
		}

		let message = MockScriptMessage(name: "document", body: "HTML content")
		messageHandler.userContentController(.init(), didReceive: message)

		let payload = try #require(await withTimeout(10) { await task.value })

		#expect(payload.data == Data("HTML content".utf8))
		#expect(payload.response == response)
	}

	@Test("Stops the WKWebView from loading and resets the contents")
	func stopLoading() async throws {
		let webView = MockWebView()
		let viewController = ViewController()
		viewController.webView = webView

		let url = URL(string: "https://example.com")!
		let data = Data(#"<!DOCTYPE html><html><body></body></html>"#.utf8)
		let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
		let stream = viewController.load(data: data, response: response)

		viewController.stopLoading()

		let payload = try await withTimeout(10) {
			var iterator = stream.makeAsyncIterator()
			return await iterator.next()
		}

		#expect(payload == nil)
		#expect(viewController.messageHandler == nil)

		#expect(webView.stopLoadingWasCalled == true)

		#expect(webView.loadDataParameters?.data == Data())
		#expect(webView.loadDataParameters?.mimeType == "text/plain")
		#expect(webView.loadDataParameters?.characterEncodingName == "UTF-8")
		#expect(webView.loadDataParameters?.baseURL == URL(fileURLWithPath: "/"))
	}

}
