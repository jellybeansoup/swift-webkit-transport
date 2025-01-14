import Foundation
import WebKit

final class MockScriptMessage: WKScriptMessage {
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
