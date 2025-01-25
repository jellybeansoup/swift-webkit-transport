// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import SwiftUI
import WebKit

#if canImport(UIKit)
struct WebView: UIViewRepresentable {

	let payload: Payload

	init(payload: Payload) {
		self.payload = payload
	}

	func makeCoordinator() -> Coordinator {
		.init()
	}

	func makeUIView(context: Context) -> WKWebView {
		makeWebView(loading: payload, coordinator: context.coordinator)
	}

	func updateUIView(_ webView: WKWebView, context: Context) {}

}
#elseif canImport(AppKit)
struct WebView: NSViewRepresentable {

	let payload: Payload

	init(payload: Payload) {
		self.payload = payload
	}

	func makeCoordinator() -> Coordinator {
		.init()
	}

	func makeNSView(context: Context) -> WKWebView {
		makeWebView(loading: payload, coordinator: context.coordinator)
	}

	func updateNSView(_ webView: WKWebView, context: Context) {}

}
#endif

extension WebView {

	class Coordinator: NSObject, WKNavigationDelegate {

		func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
			switch navigationAction.navigationType {
			case .other where navigationAction.request.url == webView.url:
				return .allow

			default:
				return .cancel
			}
		}

	}

}

private extension WebView {

	func makeWebView(loading payload: Payload, coordinator: Coordinator) -> WKWebView {
		let configuration = WKWebViewConfiguration()
		configuration.defaultWebpagePreferences.allowsContentJavaScript = false
		configuration.mediaTypesRequiringUserActionForPlayback = .all

		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.allowsLinkPreview = false

		webView.load(
			payload.data,
			mimeType: payload.response.mimeType ?? "application/octet-stream",
			characterEncodingName: payload.response.textEncodingName ?? "utf-8",
			baseURL: payload.response.url ?? URL(fileURLWithPath: "/")
		)

		webView.navigationDelegate = coordinator

		return webView
	}

}
