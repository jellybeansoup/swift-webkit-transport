// Copyright (c) 2025 Daniel Farrelly
// Licensed under BSD 2-Clause "Simplified" License
//
// See the LICENSE file for license information

import Foundation

public protocol URLSessionProtocol {

	func data(for request: URLRequest) async throws -> (Data, URLResponse)

}

extension URLSession: URLSessionProtocol {}
