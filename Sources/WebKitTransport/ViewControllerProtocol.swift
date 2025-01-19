// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation

@MainActor
protocol ViewControllerProtocol: AnyObject, Sendable {

	func load(data: Data, response: URLResponse) -> AsyncStream<WebKitTask.Payload>

	func stopLoading()

}
