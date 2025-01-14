import Foundation
import WebKit

final class MockWebView: WKWebView {

	private(set) var loadDataParameters: (
		data: Data,
		mimeType: String,
		characterEncodingName: String,
		baseURL: URL
	)?

	private(set) var stopLoadingWasCalled = false

	override func load(_ data: Data, mimeType MIMEType: String, characterEncodingName: String, baseURL: URL) -> WKNavigation? {
		loadDataParameters = (data, MIMEType, characterEncodingName, baseURL)
		return nil
	}

	override func stopLoading() {
		stopLoadingWasCalled = true
	}

}
