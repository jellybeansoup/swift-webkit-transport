// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation
import WebKit

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
